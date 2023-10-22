// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21 <0.9.0;

import "./MyFNFT.sol";

contract Game{
    event CREATED(uint256 id, address Owner);
    event BOUGHT(uint256 id, uint256 fid, uint256 Price, address Owner);
    event SETTED(uint256 id, uint256 fid, uint256 Price, address Owner);
    event SUBMITED(uint256 id, uint256 reward, address Collector);
    
    FNFT private fnft;
    uint8 public immutable fee;
    address payable immutable Organizer;
    
    constructor(uint8 _fee, address _fnft){
        fee =_fee;
        fnft = FNFT(_fnft);
        Organizer = payable(msg.sender);
    }

    receive() external payable {
        require(msg.sender == Organizer,"No authorized");
    }

    function withdraw() external payable { 
        require(msg.sender == Organizer,"Not Authorized");
        (bool success,) = Organizer.call{value:address(this).balance}("");
        require(success,"Tx Failed");
    }
    
    // Returns the prize of FNFT of given NFT ID. NFTID => FNFT ID => Price 
    mapping (uint256 => mapping (uint8 => uint256)) public _priceOf;
    
    //NFT => Reward  is collected or not for given NFT ID.
    mapping (uint256 => bool) private isCollected;
    
    //NFTID => can be bought.
    mapping(uint256 => bool) public _isForSale;
    
    //NFT ID => FNFT ID => Is Locked or unclocked for purchases
    mapping(uint256 => mapping(uint8 => bool)) public _isLocked;     

    modifier _isExist(uint tokenId){
        require(fnft._isExist(tokenId),"Id does not exist");
        _;
    }
    
    modifier _isFIDExist(uint8 fid){
        require(fid<9,"FID Does not exist");
        _;
    }

    function createNFT(uint256[] calldata price, bytes calldata data)external payable{
        
        require(price.length == 9,"Only 9 price can be assigned");
        require(msg.value== getPrice(price) ,"Price is Less use helper function");
        
        uint id = fnft.createNFT(msg.sender, data);
        unchecked{
            for (uint8 i = 0; i <= 8; i++){
                _priceOf[id][i] = price[i];
                fnft.approve(msg.sender,id, i, address(this));
                _isLocked[id][i] = true;
            }
        }
        emit CREATED(id, msg.sender);
    }

    function deleteNft(uint tokenId) external _isExist(tokenId){
        require(msg.sender == fnft.isMinter(tokenId),"Not authorized");
        require(!_isForSale[tokenId],"Given NFT ID is On sale Lock it or Given NFT ID's fraction are sold");
        require(fnft._balanceOf(msg.sender, tokenId) == 9,"First Collect All FNFTs");
        
        address owner = fnft.isMinter(tokenId);
        fnft.unfractionalize(owner, tokenId);
    }
    
    function putOnSale(uint tokenId) external _isExist(tokenId){        
        require(!_isForSale[tokenId],"Already For Sale");
        require(msg.sender == fnft.isMinter(tokenId),"Not Owner");
        _isForSale[tokenId] = true;
        
        unchecked{
            for (uint8 i = 0; i<9; i++) 
            {
                _isLocked[tokenId][i] = false;
            }
        }

    }

    function purchaseFraction(address to, uint tokenId, uint8 fid) payable external _isExist(tokenId) _isFIDExist(fid){                
        require(_isForSale[tokenId],"Not For Sale");
        require(!_isLocked[tokenId][fid],"Locked");
        require(to!= address(0),"Receiver cannot be 0 address");
        
        uint _price = _priceOf[tokenId][fid];
        require(msg.value == _price,"Price is not same");

        address owner = fnft._ownerOf(tokenId, fid);        
        (bool success,) = owner.call{value:_price}("");
        require(success,"Tx Failed");

        fnft.transferFNFT(owner, to, tokenId, fid);
        fnft.approve(msg.sender, tokenId, fid, address(this));
        _isLocked[tokenId][fid] = true;

        emit BOUGHT(tokenId, fid, _price, msg.sender);
    }

    function bid(uint tokenId, uint8 fid, uint price)external _isExist(tokenId) _isFIDExist(fid){
        require(price >0,"Price can't be zero");
        require(msg.sender == fnft._ownerOf(tokenId, fid),"Not authorized");
        require(_isLocked[tokenId][fid],"Already Bidded");

        fnft.approve(msg.sender, tokenId, fid, address(this));

        _priceOf[tokenId][fid] = price;
        _isLocked[tokenId][fid] = false;
        
        emit SETTED(tokenId, fid, price, msg.sender);
    }

    function submitCollection(uint256 tokenId)external payable _isExist(tokenId) returns(address){
        require(!isCollected[tokenId],"Reward Already Collected");
        address minter = fnft.isMinter(tokenId);
        require(payable(msg.sender) != minter,"Minter can't submit");
        require(fnft._balanceOf(msg.sender,tokenId) == 9,"Not enough FNFT's owned to collect Reward");

        address payable receiver = payable(msg.sender);
        (bool success, ) = receiver.call{value:1 ether}("");
        require(success,"Tx Failed!");

        
        fnft.unfractionalize(msg.sender,tokenId);
        fnft.safeTransferFrom(minter, msg.sender, tokenId, 1, "");
        
        isCollected[tokenId] = true;
        emit SUBMITED(tokenId,1,msg.sender);
        return minter;
    }

    function getPrice(uint256[] calldata price) public view returns(uint){
        uint _price;
        unchecked{
            for (uint i =0; i<9;i++){
                _price += price[i];
            }
        }

        uint _fee = (_price * fee)/100;
        return (_price + _fee);
    }
    function getFractionPrice(uint tokenId, uint8 fid)external view returns(uint256){
        uint _price = _priceOf[tokenId][fid];
        uint _fee = (_price * fee)/100;
        return (_price + _fee);
    }
}
