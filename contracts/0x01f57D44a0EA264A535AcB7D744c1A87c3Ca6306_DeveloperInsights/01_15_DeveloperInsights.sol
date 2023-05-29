// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";

contract DeveloperInsights is ERC1155, Ownable {

    struct MintPass {
        /// @dev Having able to set a price - in USDC (more readable to non-crypto ppl)
        uint256 passPrice;
        /// @dev To know how many in existence
        uint256 passMinted;
        /// @dev Option to close a minting period for a specific MintPass type
        bool mintingClosed;
    }

    /// Different type of mint passes (0: Tier-1, 1: Tier-2, 2: Tier-2, etc.)
    mapping(uint256 => MintPass) public _mintPasses;
    uint256 public _currentMintPassIdCnt;

    event MintPassTypeAdded(
        uint256 mintPassId,
        uint256 mintPassPrice,
        bool mintingClosed
    );

    event MintPassPriceEdited(uint256 mintPassId, uint256 newPrice);
    event MintPassMintStatusEdited(uint256 mintPassId, bool mintingClosed);
    event MintPassMinted(uint256 index, address indexed user, uint256 amount);

    /// @dev Contract name & symbol
    string public name = 'DeveloperInsights';
    string public symbol = 'DI';
    //On mainnet:
    address public _currency = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // Revenue recipient
    address public _recipient = 0xc51EecBb9c7317f701c654073Da3E069b6A112A7;

    /// @notice Check that a mint pass with given id exists
    /// @param id - Id of the mint pass
    modifier mpExists(uint256 id) {
        require(_mintPasses[id].passPrice != 0, 'Mint pass does not exists');
        _;
    }

    constructor(string memory baseUri) ERC1155(baseUri) {}

    /// @notice Add a mint pass type
    /// @param mintPassId - The id of the pass
    /// @param price - The price of the pass - can be 0 if backend has to sign something (like for SpaceCats which is a 'free' mint for coupon holders)
    /// @param mintingClosed - The status if the minting is closed (true) or not (false)
    function addMintPass(
        uint256 mintPassId,
        uint256 price,
        bool mintingClosed
    ) external onlyOwner {
        MintPass memory mp = MintPass(
            price,
            0,
            mintingClosed
        );
        
        _mintPasses[mintPassId] = mp;
        _currentMintPassIdCnt++;

        emit MintPassTypeAdded(
            mintPassId,
            price,
            mintingClosed
        );
    }

    /// @notice Mintpass' price editing
    /// @param mintPassId - The id of the pass
    /// @param newPrice - The new price
    function editPassPrice(uint256 mintPassId, uint256 newPrice)
        external
        onlyOwner
        mpExists(mintPassId)
    {
        MintPass memory mp = _mintPasses[mintPassId];

        /// @dev Modify the value and write back
        mp.passPrice = newPrice;
        _mintPasses[mintPassId] = mp;

        emit MintPassPriceEdited(mintPassId, newPrice);
    }

    /// @notice Mintpass' minting status parameter editing
    /// @param mintPassId - The id of the pass
    /// @param mintingClosed - Changing the minting status to closed (with true) or open (false)
    function editMintingClosed(uint256 mintPassId, bool mintingClosed)
        external
        onlyOwner
        mpExists(mintPassId)
    {
        MintPass memory mp = _mintPasses[mintPassId];

        /// @dev Modify the value and write back
        mp.mintingClosed = mintingClosed;
        _mintPasses[mintPassId] = mp;

        emit MintPassMintStatusEdited(mintPassId, mintingClosed);
    }

    /// @notice This function mints the passes to the user
    /// @param mintPassId - The id of the pass
    /// @param amount - Amount to be minted for the user
    function mint(
        uint256 mintPassId,
        uint256 amount
    ) external payable mpExists(mintPassId) {
        // Minting is not closed
        require(
            !_mintPasses[mintPassId].mintingClosed,
            '106 - Minting is closed currently'
        );
        
        uint256 totalPrice = amount * _mintPasses[mintPassId].passPrice;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert('107 - Not proper amount sent');
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, _recipient, totalPrice);

        _mint(msg.sender, mintPassId, amount, '');

        _mintPasses[mintPassId].passMinted += amount;

        emit MintPassMinted(mintPassId, msg.sender, amount);
    }

    /** GETTERS */

    /// @notice Returns the mint count (including the ones which are burnt already)
    /// @param mintPassId - The id of the pass
    /// @return uint256 - The number of mints
    function getMintCount(uint256 mintPassId) external view mpExists(mintPassId) returns (uint256) {
        return _mintPasses[mintPassId].passMinted;
    }

    /// @notice Returns a mint pass data
    /// @param mintPassId - The id of the pass
    /// @return mintPass - MintPass data
    function getMintPass(uint256 mintPassId)
        external
        view
        mpExists(mintPassId)
        returns (MintPass memory)
    {
        return _mintPasses[mintPassId];
    }

    /** SETTERS */

    /// @notice Set the new revenue recipient
    /// @param newRecipient Address to set as new recipient
    function setRecipient(address newRecipient) external onlyOwner {
        _recipient = newRecipient;
    }

    /// @notice Set the new currency
    /// @param newCurrency Address to set as new recipient
    function setCurrency(address newCurrency) external onlyOwner {
        _currency = newCurrency;
    }

    /// @notice Set the contract base URI
    /// @param newURI - The uri to be used
    function setContractURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }
}