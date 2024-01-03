// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    address public _contractOwner;
    uint256 public tokenCounter;
    
    mapping(uint => string) public tokenURIMap;
    mapping(uint => uint) public priceMap;

    event Minted(address indexed minter, uint price, uint nftID, string uri);
        
    event PriceUpdate(address indexed owner, uint oldPrice, uint newPrice, uint nftID);

    constructor() ERC721("OngamaNFTs", "ONGA") {
        _contractOwner = msg.sender;
        tokenCounter = 1;
    }

    function mint(string memory _uri, address _toAddress, uint _price) public returns (uint){
        uint _tokenId = tokenCounter;
        priceMap[_tokenId] = _price;

        _safeMint(_toAddress, _tokenId);
        _setTokenURI(_tokenId, _uri);

        tokenCounter++;

        emit Minted(_toAddress, _price, _tokenId, _uri);

        return _tokenId;
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(_exists(_tokenId),"ERC721Metadata: URI set of nonexistent token"); 
        tokenURIMap[_tokenId] = _tokenURI;
    }


    function updatePrice(uint _tokenId, uint _price) public returns (bool) {
        uint oldPrice = priceMap[_tokenId];
        require(msg.sender == ownerOf(_tokenId), "Error, you are not the owner");
        priceMap[_tokenId] = _price;

        emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId);

        return true;
    }

}