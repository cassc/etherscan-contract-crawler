// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ECDSA.sol"; 
import "./ToStringLib.sol";

/*                                                                                
 *                                     ~~                                       
 *                                    .BG                                       
 *                                    J&&J                                      
 *                                   ~&&&&^                                     
 *                                   G&&&&P                                     
 *                                  J&&&&&&?                                    
 *                                 ^BB&&&&BB:                                   
 *                         :Y~     J?Y&&&&J??     ~Y.                           
 *                        7#&~     7:?&&&&7:!     ~&#!                          
 *                       Y&&B.       7&#&&!       .B&&J                         
 *                     .P&&&P        7&&&&!        P&&&5.                       
 *                     P&&#&5        ?&&&&7        5&#&&5                       
 *                    Y#YB#&Y        J&&&&?        5&&GY#J                      
 *                   ~P7^J&#P        Y&&&&J        P&&J^?P~                     
 *                   ^7: ~##G        G&###P       .B&&~ :!^                     
 *                       ^###^      ^######^      ~&&&^                         
 *                       ^&&&Y      5######Y      5&&#:                         
 *                       ^&&&#^    7########7    ~&&&#:                         
 *                       !&###B7^~Y########&&Y~^?#####~                         
 *                       Y&##############&&&&&&#&#####J                         
 *                      .G############&&&&&&##########G                         
 *                      ?###########&&&&&#############&7                        
 *                     .Y5PGGBB##&&&&&###########BBGGP5J.                       
 *                      .:^~!7?J5PB##########BP5J?7!~^:.                        
 *                             .:^7YG######GY7~:.                               
 *                                 .~YB##BY~.                                   
 *                                   .7BB?.                                     
 *                                     ??                                       
 *                                     ..                                       
 */                                                                              

contract HolyNephalem is ERC721A, Ownable, ReentrancyGuard {

    /* Variables */

    uint256 public mintPrice = 0.05 ether;
    uint128 public maxMintsPerTxn = 2;
    uint128 public maxSupply = 5050;
    string private _baseTokenURI;
    bool private _paused = true;
    bool private _privatePaused = true;
    address private _authority = address(0);

    /* Construction */

    constructor() ERC721A("Holy Nephalem", "NEPHALEMS") {
        constructDistribution();
    }

    /* Config */

    /// @notice Gets the total minted
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Gets all required config variables
    function config() external view returns(uint256, uint128, uint128, uint256, bool, bool) {
        return (mintPrice, maxMintsPerTxn, maxSupply, _totalMinted(), _paused, _privatePaused);
    }

    /* Mint */

    /// @notice Private mint function that requires signature authorisation
    /// @dev Signature required mint function using ECDSA verification.
    function privateMint(uint256 quantity, bytes memory signature) external payable nonReentrant {
        require(_privatePaused == false, "Cannot mint while paused");
        require(msg.value == quantity * mintPrice, "Must send exact mint price.");
        require(quantity <= maxMintsPerTxn, "Cannot mint over maximum allowed mints per transaction.");
        require(isValidAccessMessage(signature), "Mint access not granted!");
        _internalMint(msg.sender, quantity);
    }

    /// @notice Public mint function that accepts a quantity.
    /// @dev Mint function with price and maxMints checks.
    function mint(uint256 quantity) external payable nonReentrant {
        require(_paused == false, "Cannot mint while paused");
        require(msg.value == quantity * mintPrice, "Must send exact mint price.");
        require(quantity <= maxMintsPerTxn, "Cannot mint over maximum allowed mints per transaction");
        _internalMint(msg.sender, quantity);
    }

    /// @notice Minting functionality for the contract owner.
    /// @dev Owner mint with no checks other than those included in _internalMint()
    function ownerMint(uint256 quantity) external onlyOwner nonReentrant {
        _internalMint(msg.sender, quantity);
    }

    /// @dev Internal mint function that runs basic max supply check.
    function _internalMint(address to, uint256 quantity) private {
        require(_totalMinted() + quantity <= maxSupply, "Exceeded max supply");
        _safeMint(to, quantity);
    }

    /* Whitelist */

    function isValidAccessMessage(bytes memory signature) private view returns (bool) {
        bytes32 internalHash = keccak256(bytes(interalAccessor()));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(internalHash);
        return _authority == ECDSA.recover(messageHash, signature);
    }

    function interalAccessor() private view returns(string memory) {
        return string(abi.encodePacked(ToStringLib.toString(address(this)), ToStringLib.toString(msg.sender)));
    }

    /* Metadata */

    /// @dev Override to pass in metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Ownership */

    /// @notice Gets all the token IDs of an owner
    /// @dev Should not be called internally. Runs a simple loop to calcute all the token IDs of a specific address.
    function tokensOfOwner(address owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;

            for (id = 0; id < total; id++) {
                if (ownerOf(id) == owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Prevents ownership renouncement
    function renounceOwnership() public override onlyOwner {}

    /* Interface Support */

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /* Fallbacks */

    receive() payable external {}
    fallback() payable external {}

    /* Owner Functions */

    /// @notice Sets the mint price in WEI
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    /// @notice Sets the max supply of the collection
    function setMaxSupply(uint128 supply) external onlyOwner {
        maxSupply = supply;
    }

    /// @notice Sets the maximum number of tokens per mint
    function setMaxMintsPerTxn(uint128 maxMints) external onlyOwner {
        maxMintsPerTxn = maxMints;
    }

    /// @notice Sets the Token URI for the Metadata
    function setTokenURI(string memory uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @notice Sets the public mint to paused or not paused
    function setPaused(bool pause) external onlyOwner {
        _paused = pause;
    }

    /// @notice Sets the private mint to paused or not paused
    function setPrivatePaused(bool pause) external onlyOwner {
        _privatePaused = pause;
    }

    /// @notice Sets the whitelist address authority
    function setAuthority(address auth) external onlyOwner {
        _authority = auth;
    }

    /* Funds */

    uint16 private shareDenominator = 10000;
    uint16[] private shares;
    address[] private payees;

    /// @notice Assigns payees and their associated shares
    /// @dev Uses the addPayee function to assign the share distribution
    function constructDistribution() private {
        addPayee(0xFC93CA5348F580465352B775b11e52DB88F33023, 3850);
        addPayee(0xdCA2CfCBd294b86bE596CF3AE8ef4c5B2e52Afbd, 3850);
        addPayee(0xe893a628C73f7A4c7742A273328a545293B785ce, 1000);
        addPayee(0xb71BF456529a0392C48EFAE846Cf6d30C705561D, 500);
        addPayee(0x86212f0fe1944f37208e0A71c81c772440B89eF6, 800);
    }

    /// @notice Adds a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function addPayee(address payee, uint16 share) public onlyOwner {
        require(payees.length == shares.length, "Payee and shares must be the same length.");
        require(totalShares() + share <= shareDenominator, "Cannot overassign share distribution.");
        payees.push(payee);
        shares.push(share);
    }

    /// @notice Updates a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function updatePayee(address payee, uint16 share) external onlyOwner {
        require(address(this).balance == 0, "Must have a zero balance before updating payee shares");
        for (uint i=0; i < payees.length; i++) {
            if(payees[i] == payee) shares[i] = share;
        }
        require(totalShares() <= shareDenominator, "Cannot overassign share distribution.");
    }

    /// @notice Removes a payee from the distribution list
    /// @dev Sets a payees shares to zero, but does not remove them from the array. Payee will be ignored in the distributeFunds function
    function removePayee(address payee) external onlyOwner {
        for (uint i=0; i < payees.length; i++) {
            if(payees[i] == payee) shares[i] = 0;
        }
    }

    /// @notice Gets the total number of shares assigned to payees
    /// @dev Calculates total shares from shares[] array.
    function totalShares() private view returns(uint16) {
        uint16 sharesTotal = 0;
        for (uint i=0; i < shares.length; i++) {
            sharesTotal += shares[i];
        }
        return sharesTotal;
    }

    /// @notice Fund distribution function.
    /// @dev Uses the payees and shares array to calculate 
    function distributeFunds() external onlyOwner nonReentrant {

        uint currentBalance = address(this).balance;

        for (uint i=0; i < payees.length; i++) {
            if(shares[i] == 0) continue;
            uint share = (shares[i] * currentBalance) / shareDenominator;
            (bool sent,) = payable(payees[i]).call{value : share}("");
            require(sent, "Failed to distribute to payee.");
        }

        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }
}