// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


interface IERC4907 {

    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    event TokenOwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 tokenId);
    // event TransferOwner(uint256 indexed tokenId, address newOwner);
    //event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); //adding

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

contract TransferOwnerShip is ERC721, IERC4907 {
    struct UserInfo 
    {
        address user;   // address of user role
        uint64 expires; // unix timestamp, user expires
        // uint256 tokenId;
    }

    mapping (uint256  => UserInfo) internal _users;

    mapping(address => mapping (address => uint256)) allowed; //adding 
    address public _owner; // adding 


    constructor(string memory name_, string memory symbol_)
     ERC721(name_, symbol_)
     {
        _owner=msg.sender; //adding
        emit TokenOwnershipTransferred(address(0), _msgSender(), uint256(0)); 
     }
    
    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) public override virtual{
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC4907: transfer caller is not owner nor approved");
        UserInfo storage info =  _users[tokenId];

        //require(info.expires < block.timestamp, "Already rentedto someone"

        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    function transferOwnership(address newOwner, uint256 tokenId) public virtual payable  {
      // require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(_isApprovedOrOwner(msg.sender, tokenId));
        ownerOf(tokenId) == newOwner;
        _transfer(_owner, newOwner, tokenId);
        
    }

    // require(ownerOf(1) == _owner, "Already bought");
    // _transfer(_owner, msg.sender, 1);

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
       if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return  _users[tokenId].expires;
        }  else{
              return 115792089237316195423570985008687907853269984665640564039457584007913129639935;
       }
    }  

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view  override virtual  returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }

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

    function mint(uint256 tokenId) public {
        _mint(msg.sender, tokenId);
    }

    function time() public view returns (uint256) {
        return block.timestamp;
    }
      //adding
    //     modifier onlyOwner()   virtual {
    //     require(_owner == _msgSender(), "Ownable: caller is not the owner");
    //     _;
    // }

}  