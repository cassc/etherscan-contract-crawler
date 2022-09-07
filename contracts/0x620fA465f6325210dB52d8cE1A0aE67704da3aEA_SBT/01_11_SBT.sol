// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


/**
 * @dev Modifier 'onlyOwner' becomes available, where owner is the contract deployer
 */ 
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @dev ERC721Enumerable
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface IERC5192 {
  /// @notice Returns the locking status of an Soulbound Token
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param tokenId The identifier for an SBT.
  function locked(uint256 tokenId) external view returns (bool);
}


contract SBT is Ownable, ERC721 {


    // --- VARIABLES --- //

    address public roundContract;

    string public uriString;

    uint public totalSupply;


    // --- CONSTRUCTOR --- //
   
    constructor(string memory _uriString) ERC721("3xcalibur Public Round", "XCAL-SBT") {

        uriString = _uriString;

    }



    // --- EVENTS --- //

    event TokenMinted(address indexed recipient, uint tokenId);


    // --- EXTERNAL --- //

    function mint(address _user) external {

        require(
            msg.sender == roundContract,
            "Function only callable by round contract address"
        );

        totalSupply++;
        _safeMint(_user, totalSupply);

        emit TokenMinted(_user, totalSupply);
    }


    // --- VIEW --- //

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {

        return interfaceId == 0xb45a3c0e || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns locked status of token number 'tokenId'. Required for EIP-5192 compliance
     */
    function locked(uint256 tokenId) public view returns(bool) {

        require(
            ownerOf(tokenId) != address(0),
            "invalid token owner"
        );

        return true;
    }
    
    /**
     * @dev Returns tokenURI
     */
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {

        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return uriString;
    }


    // --- TRANSFER FUNCTION OVERRIDE --- //

    modifier transferThrower() {
        require(
            false == true,
            "Tokens are soul-bound and cannot be transferred"
        );
        _;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) transferThrower {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721) transferThrower {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) transferThrower {}

    
    // --- ONLY OWNER --- //

    /**
     * @dev Set the Round contract address
     * @param _address - address of Round contract
     */
    function setRoundContractAddress(address _address) public onlyOwner{
        roundContract =  _address;
    }

}