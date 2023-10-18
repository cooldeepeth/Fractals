// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MyFNFT.sol";

contract Game{
    
    event CREATED(uint256 id, uint256 Price, address Owner);
    event BOUGHT(uint256 id, uint256 fid, uint256 Price, address Owner);
    event SETTED(uint256 id, uint256 fid, uint256 Price, address Owner);
    event SUBMITED(uint256 id, uint256 reward, address Collector);

    MyToken private immutable token;
    address private immutable Organizer;
    uint8 public fee;
    constructor(address _address, uint8 _fee) {
        token = MyToken(_address);
        fee = _fee;
        Organizer = msg.sender;
    }

    receive() external payable { 
        require(msg.sender == Organizer,"");
    }

    //Address -> NFT Minter
    mapping(uint => address) private Minter;
    
    //NFT ID -> Exist or not
    mapping (uint => bool) private _isExist;
    
    //NFT ID -> FNFT ID -> isLockedForSubmitOrBuy 
    mapping (uint=> mapping(uint=> bool)) isLocked;
    
    //NFT ID -> Reward Collected Of Given NFTID
    mapping(uint => bool) public Collected;
    
    uint256 private counter;
    
    function createNFT(uint256 price, bytes memory data,string memory tokenURI)external returns(uint){    
        
        // require(msg.value == price,"Msg value must be equal to pirce");
        
        counter++;
        token.mintBatch(msg.sender, counter, price, data,tokenURI);
        
        Minter[counter]=msg.sender;
        
        _isExist[counter] = true;

        emit CREATED(counter, price, msg.sender);
        return counter;
    }

    function buy(uint id, uint fid) external payable returns(bool){
        require(!_isExist[id],"Id exist");    
        require(!isLocked[id][fid],"Cannot Buy Locked By Owner");
        require(fid <= 8, "FID not Exist");

        uint price = getPrice(id,fid);
        require(msg.value == price ,"Price does not match");
        
        address owner = token.ownerOf(id,fid);
        (bool success,) = owner.call{value:msg.value}("");
        require(success,"Tx failed");

        token.transfer(owner, msg.sender, id, fid);
        isLocked[id][fid] = true;

        emit BOUGHT(id, fid, price, msg.sender);
        return true;
    }
    
    function getPrice(uint id, uint fid) public view returns(uint price){
        price = (token.priceOf(id, fid));
        uint _fee = (price * fee) / 100;
        price = price + _fee;
    }

    function unLock(uint id, uint fid)external{
        require(token.ownerOf(id,fid) == msg.sender,"Not Owner");
        require(_isExist[id],"ID Does not Exist");
        require(fid <= 8,"FID does not exist");
        require(isLocked[id][fid],"Fid is not locked");
        isLocked[id][fid] = false;
    }

    function setPrice(uint id, uint fid, uint price)external{
    
        require(_isExist[id],"Id Does not exist");
        require(fid<=8,"FID Not Exist");
        require(token.ownerOf(id,fid) == msg.sender,"Not Owner of given fnft");
        
        token.changePrice(id, fid, price);
        emit SETTED(id, fid, price, msg.sender);
    }

    function submitFnfts(uint id)external payable{
        require(!Collected[id],"Reward Already Collected");
        require(msg.sender != Minter[id],"Minter can't submit");
        
        require(_isExist[id],"ID does not exist");
        require(token.FNFTBalance(msg.sender,id)==8,"Collect all FNFTs");
        
        (bool success, ) = msg.sender.call{value:1 ether}("");
        require(success,"Tx Failed!");
        
        Collected[id] = true;
        emit SUBMITED(id,1,msg.sender);
    }

}