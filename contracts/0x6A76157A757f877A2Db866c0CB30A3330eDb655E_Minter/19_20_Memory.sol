// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Minter.sol";

/**
          _____                    _____                    _____                   _______                   _____                _____          
         /\    \                  /\    \                  /\    \                 /::\    \                 /\    \              |\    \         
        /::\____\                /::\    \                /::\____\               /::::\    \               /::\    \             |:\____\        
       /::::|   |               /::::\    \              /::::|   |              /::::::\    \             /::::\    \            |::|   |        
      /:::::|   |              /::::::\    \            /:::::|   |             /::::::::\    \           /::::::\    \           |::|   |        
     /::::::|   |             /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/\:::\    \          |::|   |        
    /:::/|::|   |            /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/__\:::\    \         |::|   |        
   /:::/ |::|   |           /::::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /::::\   \:::\    \        |::|   |        
  /:::/  |::|___|______    /::::::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /::::::\   \:::\    \       |::|___|______  
 /:::/   |::::::::\    \  /:::/\:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/\:::\   \:::\____\      /::::::::\    \ 
/:::/    |:::::::::\____\/:::/__\:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/  \:::\   \:::|    |    /::::::::::\____\
\::/    / ~~~~~/:::/    /\:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \::/   |::::\  /:::|____|   /:::/~~~~/~~      
 \/____/      /:::/    /  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \/____|:::::\/:::/    /   /:::/    /         
             /:::/    /    \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /          |:::::::::/    /   /:::/    /          
            /:::/    /      \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /           |::|\::::/    /   /:::/    /           
           /:::/    /        \:::\   \::/    /               /:::/    /         \::::::::/    /            |::| \::/____/    \::/    /            
          /:::/    /          \:::\   \/____/               /:::/    /           \::::::/    /             |::|  ~|           \/____/             
         /:::/    /            \:::\    \                  /:::/    /             \::::/    /              |::|   |                               
        /:::/    /              \:::\____\                /:::/    /               \::/____/               \::|   |                               
        \::/    /                \::/    /                \::/    /                 ~~                      \:|   |                               
         \/____/                  \/____/                  \/____/                                           \|___|                               
                                                                                                                                                  
          _____                    _____                    _____                    _____                    _____        _____                  
         /\    \                  /\    \                  /\    \                  /\    \                  /\    \      |\    \                 
        /::\    \                /::\____\                /::\    \                /::\    \                /::\____\     |:\____\                
       /::::\    \              /:::/    /               /::::\    \              /::::\    \              /:::/    /     |::|   |                
      /::::::\    \            /:::/    /               /::::::\    \            /::::::\    \            /:::/    /      |::|   |                
     /:::/\:::\    \          /:::/    /               /:::/\:::\    \          /:::/\:::\    \          /:::/    /       |::|   |                
    /:::/__\:::\    \        /:::/    /               /:::/__\:::\    \        /:::/__\:::\    \        /:::/    /        |::|   |                
    \:::\   \:::\    \      /:::/    /               /::::\   \:::\    \      /::::\   \:::\    \      /:::/    /         |::|   |                
  ___\:::\   \:::\    \    /:::/    /      _____    /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/    /          |::|___|______          
 /\   \:::\   \:::\    \  /:::/____/      /\    \  /:::/\:::\   \:::\____\  /:::/\:::\   \:::\____\  /:::/    /           /::::::::\    \         
/::\   \:::\   \:::\____\|:::|    /      /::\____\/:::/  \:::\   \:::|    |/:::/  \:::\   \:::|    |/:::/____/           /::::::::::\____\        
\:::\   \:::\   \::/    /|:::|____\     /:::/    /\::/    \:::\  /:::|____|\::/    \:::\  /:::|____|\:::\    \          /:::/~~~~/~~              
 \:::\   \:::\   \/____/  \:::\    \   /:::/    /  \/_____/\:::\/:::/    /  \/_____/\:::\/:::/    /  \:::\    \        /:::/    /                 
  \:::\   \:::\    \       \:::\    \ /:::/    /            \::::::/    /            \::::::/    /    \:::\    \      /:::/    /                  
   \:::\   \:::\____\       \:::\    /:::/    /              \::::/    /              \::::/    /      \:::\    \    /:::/    /                   
    \:::\  /:::/    /        \:::\__/:::/    /                \::/____/                \::/____/        \:::\    \   \::/    /                    
     \:::\/:::/    /          \::::::::/    /                  ~~                       ~~               \:::\    \   \/____/                     
      \::::::/    /            \::::::/    /                                                              \:::\    \                              
       \::::/    /              \::::/    /                                                                \:::\____\                             
        \::/    /                \::/____/                                                                  \::/    /                             
         \/____/                  ~~                                                                         \/____/                              
                                                                                                                                                  
@title Memory
@author @sammdec
@notice Create to play
*/

contract Memory is ERC721, ERC721Royalty, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using Address for address;

    // @notice Counter for tokenIds
    Counters.Counter private _tokenIdCounter;

    // @notice the Minter contract
    // @dev Only this has permission to mint
    Minter public minter;

    // @notice Base URI for tokenURI
    string public baseURI;

    // @notice Default royalty is 5% in basis points
    uint96 public ROYALTY = 500;

    // @notice Beneficiary address for withdraws
    address public beneficiary;
    // @notice Mapping of token ID's to design ID's e.g 1 => 1_1_1_1
    mapping(uint256 => string) public tokenIdsToDesignIds;

    // @notice Mapping of design ID's to token ID's e.g 1_1_1_1 => 1
    mapping(string => uint256) public designIdsToTokenIds;

    // @notice Event emitted when a token is minted
    event Mint(address indexed _to, uint256 _tokenId, string _designId);

    // @notice Initializes the contract by setting a `name` and a `symbol`, sets the baseURI from the argument, sets the default royalty receiver to the contracts address and increments the token ID so that we start with 1.
    constructor(string memory _baseURI) ERC721("Memory", "MEMORY") {
        baseURI = _baseURI;

        // Increments on deploy as we start tokenId's at 1
        _tokenIdCounter.increment();
        _setDefaultRoyalty(address(this), ROYALTY);
    }

    // @notice modifier to only allow the Minter contract to call functions
    modifier onlyMinter() {
        require(
            address(minter) == msg.sender,
            "Caller is not the minter contract"
        );
        _;
    }

    // @notice Mints a new Memory
    // @dev Can only be called from the Minter contract
    // @param recipient The address that called the mint function and will receive this token
    // @param designId The ID in string format e.g 1_1_1_1
    function mintFromMinter(
        address recipient,
        string calldata designId
    ) external onlyMinter returns (uint256) {
        // Check this design ID doesnt alreayd exist
        require(designIdsToTokenIds[designId] == 0, "Design ID already exists");

        // Get the current token ID and store a ref to it
        uint256 tokenId = _tokenIdCounter.current();
        // Mint using the current token ID
        _mint(recipient, tokenId);

        // Add the newly used token ID and set the components ID
        tokenIdsToDesignIds[tokenId] = designId;
        // Add the components ID and set the token ID of it
        designIdsToTokenIds[designId] = tokenId;

        // Emit the Mint event
        emit Mint(recipient, tokenId, designId);

        // increment the tokenID counter for the next mint
        _tokenIdCounter.increment();

        //  Return the token ID
        return tokenId;
    }

    // @notice Get the tokenURI for the given token ID
    // @param tokenId The token ID we are looking up
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        // If the owner of this token ID is 0 it means it hasnt been minted or someone has sent it to the 0 address
        require(ownerOf(tokenId) != address(0), "Token ID does not exist");

        // Our API actually doesnt use the tokenID it uses the design ID so we get it from the mapping
        string memory designId = tokenIdsToDesignIds[tokenId];

        // Concatenate the baseURI and designID to create the full url
        return string.concat(baseURI, designId);
    }

    // @notice Gets the current token ID, this will be the next one to be minted
    function currentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Admin functions
     */

    // @notice Sets the Minter address
    // @param _minter The minter contract address
    function setMinter(Minter _minter) external onlyOwner {
        minter = _minter;
    }

    // @notice Sets the baseURI
    // @dev This should contain an end slash (/) due to the way concatenation happens
    // @param _baseURI The new base URI string
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // @notice Sets the beneficiary of where funds are sent
    // @param _beneficiary Sets the new beneficiary address
    function setBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    // @notice Withdraws ETH from this contract to the beneficiary address
    function withdraw() external {
        require(beneficiary != address(0), "Beneficiary address not set");
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "Withdraw unsuccessful");
    }

    // @notice Allows the withdrawal of ERC20's that have been sent to this contract to the beneficiary
    // @param _erc20Token The address of the token to be withdrawn
    function withdrawERC20(IERC20 _erc20Token) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary address not set");
        _erc20Token.transfer(beneficiary, _erc20Token.balanceOf(address(this)));
    }

    /**
     * @dev Overrides
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // @notice A default receive function in case anyone or any other contract tries to send ETH to this contract
    receive() external payable {}
}