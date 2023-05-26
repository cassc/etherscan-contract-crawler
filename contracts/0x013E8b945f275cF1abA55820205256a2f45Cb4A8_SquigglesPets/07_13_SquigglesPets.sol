// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SquigglesPets is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    /* Variables */

    uint256 public mintPrice = 0.00 ether;
    uint128 public maxMintsPerTxn = 2;
    uint128 public maxSupply = 5000;
    string private _baseTokenURI;
    bool private _paused = true;
    bool private _privatePaused = true;
    address private _squiggles = 0xBa07CD4712a308BE5F117292a07bEff94a7fE0cF;
    IERC721 private _squigglesContract;
    
    /* Construction */

    constructor() ERC721A("Squiggles Pets", "SQUIGGLES PETS") {
        _squigglesContract = IERC721(_squiggles);
        constructDistribution();
    }

    /* Modifiers */

    modifier verify(address minter, uint quantity) {
       uint squiggleCount = ownedSquiggles(minter);
       require(quantity <= squiggleCount, "Unathorised function call.");
       _;
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

    /// @notice Private mint function
    /// @dev Cross checks squiggles contract NFT count
    function privateMint(uint256 quantity) external payable verify(msg.sender, quantity) nonReentrant {
        require(_privatePaused == false, "Cannot mint while paused");
        require(msg.value == quantity * mintPrice, "Must send exact mint price.");
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

    /* Metadata */

    /// @dev Override to pass in metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Ownership */

    /// @notice Gets the amount of squiggles tokens owned
    /// @dev References IERC721 to call balanceOf
    function ownedSquiggles(address owner) internal view returns(uint ownedToken) {
        return _squigglesContract.balanceOf(owner);
    }

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

    /* Operator Filter */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
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

    /// @notice Sets the squiggles address and contrac
    function setSquigglesAddress(address squiggles) external onlyOwner {
        _squiggles = squiggles;
        _squigglesContract = IERC721(_squiggles);
    }

    /* Funds */

    uint16 private shareDenominator = 10000;
    uint16[] private shares;
    address[] private payees;

    /// @notice Assigns payees and their associated shares
    /// @dev Uses the addPayee function to assign the share distribution
    function constructDistribution() private {
        //No funds
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

    /// @notice ERC20 fund distribution function.
    /// @dev Uses the payees and shares array to calculate. Will send all remaining funds to the msg.sender.
    function distributeERC20Funds(address tokenAddress) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint currentBalance = tokenContract.balanceOf(address(this));

        for (uint i=0; i < payees.length; i++) {
            if(shares[i] == 0) continue;
            uint share = (shares[i] * currentBalance) / shareDenominator;
            tokenContract.transfer(payees[i], share);
        }

        if(tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
        }
    }
}