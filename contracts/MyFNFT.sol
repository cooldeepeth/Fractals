// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract FNFT is ERC1155 {
    address private gameContract;
    
    function setGameContract(address _addr) external{
        gameContract = _addr;
    }

    constructor() ERC1155(""){}

    mapping(uint => bool) public _isExist;
    
    mapping(uint256 => mapping(uint =>bool)) isLocked;

    mapping(uint256 => address) private _Minter;

    mapping(uint => bool) public _isInitialized;


    mapping(address => mapping(uint256 => uint256)) public _balanceOf;

    mapping(uint256 => mapping(uint8 => address)) public _ownerOf;

    mapping(uint256=> mapping(uint8=> uint256)) public _priceOf;
    
    uint256 private counter;

    modifier isExist(uint id){
        require(_isExist[id],"Id Does not exist");
        _;
    }
    function isMinter(uint256 tokenId) external view returns(address){
        return _Minter[tokenId];
    }

    function createNFT(address to, bytes calldata data) external returns(uint){
        uint tokenId = counter + 1;
        require(!_isExist[tokenId],"ID exist");
        
        _mint(to, tokenId, 1, data);
        _setApprovalForAll(to, msg.sender, true);
        fractionalize(to,tokenId,data);

        _isExist[tokenId] = true;
        _isInitialized[tokenId] = true;
        
        _Minter[tokenId] = to;
        _balanceOf[to][tokenId] = 9;  
        counter = tokenId;
        return counter;
    }

    function fractionalize(address _to, uint tokenId, bytes calldata data)internal{    
        // _mint(msg.sender, tokenId, 9, data);
        uint[] memory ids = new uint256[](9);
        uint[] memory values= new uint256[](9);

        unchecked{
            for (uint i = 0; i<9; i++) 
            {
                ids[i] = tokenId;
                values[i] = 1;
                isLocked[tokenId][i]=true;

            }
        }
        // _mint(_to, tokenId, 9, data);
        _mintBatch(_to, ids, values, data);
        unchecked{
            for (uint8 i = 0 ; i<9; i++) 
            {
                _ownerOf[tokenId][i] = _to;
            }
        }
    }

    function unfractionalize(uint tokenId) external isExist(tokenId) {
        require(_isInitialized[tokenId],"Not Fracted");
        require(msg.sender == _Minter[tokenId],"Not Owner");
        // require(!_isForSale[tokenId],"NFT is on sale");
       
        _burn(msg.sender, tokenId, 9);
        
        _isExist[tokenId] = false;
        _isInitialized[tokenId] = false;
    
        _Minter[tokenId] = address(0);
        _balanceOf[msg.sender][tokenId] = 0;
        unchecked{
            for (uint8 i = 0; i<9; i++) 
            {
                _ownerOf[tokenId][i] = address(0);
                _priceOf[tokenId][i] = 0;
            }
        }
    }    

    function approve(uint256 tokenId, uint8 fid, address operator)external isExist(tokenId){
        require(fid<=8,"FID does not Exist");
        require(operator != address(0),"Invalid Operator");
        setApprovalForAll(operator, true);
    }

    function transferFNFT(address from, address to, uint tokenId, uint8 fid) external isExist(tokenId){
        require(msg.sender == _ownerOf[tokenId][fid] || isApprovedForAll(from, msg.sender),"Not Authorized");

        require(from == _ownerOf[tokenId][fid],"From is Not Owner of given NFT");
        require(to!= address(0));
        require(fid <=8,"FID doesnot exist");
        safeTransferFrom(from, to, tokenId, 1, "");

        _balanceOf[to][tokenId] +=1;
        _balanceOf[from][tokenId] -=1;

        _ownerOf[tokenId][fid]= to;
    }
    
    function transferBatch(address from, address to, uint tokenId) external {
        require(isApprovedForAll(from, msg.sender),"Not Authorized");
        require(from != address(0),"Invalid Sender");
        require(to != address(0),"Invalid Receiver");
        
        safeTransferFrom(from, to, tokenId, 1, "");
    }
}
