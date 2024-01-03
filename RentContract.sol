// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";





interface IERC4907 {

    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    // event TransferOwner(uint256 indexed tokenId, address newOwner);
    //event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); //adding
   event TokenOwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 indexed tokenId);
    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);

  //  function transferOwnership(address newOwner) external;

}

contract TransferRenting is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, IERC4907 {

    struct UserInfo
    {
        address user;   // address of user role
        uint64 expires; // unix timestamp, user expires
    }



    mapping (uint256  => UserInfo) internal _users;   //

    mapping(address => mapping (address => uint256)) allowed; //adding
    address public _owner; // adding

    string public baseURI = "https://stormwarfare.s3.eu-central-1.amazonaws.com";



    constructor()
     ERC721("StormWarfare", "SW") {

          _owner= msg.sender;

      }

   // Check the contract owner to executed ,

    modifier onlyOwner() override  virtual {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires

    function setUser(uint256 tokenId, address user, uint64 expires) public override virtual{
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC4907: transfer caller is not owner nor approved");
        UserInfo storage info =  _users[tokenId];

        require(info.expires < block.timestamp, "Already rented to someone");

        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }


    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view override virtual returns(address){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return  _users[tokenId].user;
        }
        else{

            return ownerOf(tokenId);
            // return address(0);
        }
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT


    function userExpires(uint256 tokenId) public view override virtual returns(uint256){
            return  _users[tokenId].expires;

    }

    /// @dev See {IERC165-supportsInterface}.
    //check if the address account supports the given interfaceId
    // TO restrict what kind of contracts that can be supplied to the function. Each contract you want to allow for needs to implement ERC165

    function supportsInterface(bytes4 interfaceId) public view  override virtual  returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }


   //Hook that is called before any transfer of tokens. This includes minting and burning.
   //from && to  cannot be the zero addresses.


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        super._beforeTokenTransfer(from, to, tokenId, 0);

        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }


    //Show the current time

    function time() public view returns (uint256) {
        return block.timestamp;
    }

        /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */

    function _isApprovedOrOwner(address user, uint256 tokenId) internal view virtual   override returns (bool) {
        require(_exists(tokenId), " operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        // console.log("spender %s", user);
        // console.log("getApproved %s", getApproved(tokenId);
        return (user == owner || isApprovedForAll(owner, user) || getApproved(tokenId) == user);
    }
      //adding

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }


    //base URI for all token IDs.It is automatically added as a prefix to the value returned in tokenURI,

    function _baseURI() internal view override returns (string memory) {
         return   baseURI;
    }

    //The _safeMint flavor of minting causes the recipient of the tokens, if it is a smart contract, to react upon receipt of the tokens.

    function safeMint(address to, uint256 tokenId, string memory uri)
        public

    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    // Destroys amount tokens from account, reducing the total supply.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

        function _afterTokenTransfer(address from, address to, uint256 firstTokenId) internal virtual {}
}