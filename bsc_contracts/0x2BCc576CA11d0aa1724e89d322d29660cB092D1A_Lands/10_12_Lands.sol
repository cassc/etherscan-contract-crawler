// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev open source tokenity vendor contract
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev security
import "./security/ReEntrancyGuard.sol";
import "./security/Administered.sol";

/// @dev helpers
import "./Interfaces/IPropertyToken.sol";

contract Lands is Administered, ReEntrancyGuard {
    /// @dev set Address
    address tokenAddress = address(0);

    bool public isPaused = false;

    struct StructLands {
        address wallet;
        uint256 amountLands;
        uint256 timestamp;
        bool withdrawal;
    }

    /// @dev mapping
    mapping(uint256 => StructLands) public LandsWithdrawal;

    constructor(address _addr) {
        tokenAddress = _addr;
    }

    /// @dev create a new land
    function createCodeLand(
        uint256 _code,
        uint256 _amount
    ) external onlyUser returns (bool) {
        /// @dev check if the land is already created
        require(!LandsWithdrawal[_code].withdrawal, "Land already created");

        /// @dev create a new land
        LandsWithdrawal[_code] = StructLands(address(0), _amount, 0, true);

        return true;
    }

    /// @dev remove code
    function removeCodeLand(uint256 _code) external onlyUser returns (bool) {
        /// @dev remove a land
        LandsWithdrawal[_code] = StructLands(address(0), 0, 0, false);
        return true;
    }

    /// @dev mint gift tokens
    function mintLands(
        uint256 _code
    ) external payable noReentrant returns (bool) {
        /// @dev is active
        require(!isPaused, "Contract is paused");

        /// @dev check if the land is already created
        StructLands memory _land = LandsWithdrawal[_code];

        /// @dev check if the land is already created
        require(_land.withdrawal, "Mint Gifts Land already removed");

        /// @dev Transfer token to the sender
        IPropertyToken(tokenAddress).mintReserved(
            _msgSender(),
            _land.amountLands
        );

        /// @dev remove a land
        LandsWithdrawal[_code] = StructLands(
            _msgSender(),
            _code,
            block.timestamp,
            false
        );
        return true;
    }

    /// @dev set active mint land

    function setActiveMintLand(bool _active) external onlyAdmin returns (bool) {
        isPaused = _active;
        return true;
    }

    /// @dev set token address
    function setTokenAddrresNft(
        address _tokenAddress
    ) external onlyAdmin returns (bool) {
        tokenAddress = _tokenAddress;
        return true;
    }

    /// @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawOwner(
        uint256 amount,
        address to
    ) external payable onlyAdmin returns (bool) {
        require(
            payable(to).send(amount),
            "withdrawOwner: Failed to transfer token to fee contract"
        );
        return true;
    }
}