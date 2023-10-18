// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract MyToken is ERC1155, ERC1155Burnable {
    constructor() ERC1155("") {}

    //NFT ID -> Address of Minter
    // NFT Id => FID => Owner of Fraction FID
    mapping(uint256 => mapping(uint256 => address)) public ownerOf;

    //NFT ID -> FNFT ID -> PRICE
    mapping(uint256 => mapping(uint256 => uint256)) public priceOf;

    //OWNER -> NFTID -> TOTAL FNFT BALANCE
    mapping(address => mapping(uint256 => uint256)) public _balanceOf;
    
    //NFT ID -> IS EXIST
    // mapping(uint => bool) public _isExist;

    // NFTID -> FNFT ID -> TOKENURI
    mapping(uint => mapping(uint => string)) public TokenURI;

    function setURI(string memory newuri) public  {
        _setURI(newuri);
    }

    function mintBatch(address to, uint256 id,uint256 priceOfEachFraction,bytes memory data, string memory tokenURI)
        public
    {
        unchecked{
           for (uint i = 0; i<9; i++) 
           {                
                ownerOf[id][i] = to;
                _balanceOf[to][id] += 1;
                priceOf[id][i] = priceOfEachFraction;
                // TokenURI[id][i]=tokenURI[i];
           }
                _setURI(tokenURI);
        }
        _mint(to, id, 1, data);
    }
    
    function transfer(address from, address to, uint id, uint fid) external {    
        ownerOf[id][fid]=to;
        _balanceOf[from][id] -= 1;
        _balanceOf[to][id] += 1;
    }

    function changePrice(uint id, uint fid, uint price)  external{
        priceOf[id][fid] = price;
    }

    function FNFTBalance(address to ,uint id) external view returns(uint){
        return _balanceOf[to][id];
    }
}