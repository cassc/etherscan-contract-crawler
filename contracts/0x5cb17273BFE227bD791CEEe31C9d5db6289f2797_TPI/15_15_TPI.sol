// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IgNFT {
    /// @notice View method to read SegmentManagement contract address
    /// @return Address of SegmentManagement contract
    function SEGMENT_MANAGEMENT() external view returns (address);
}

interface ISupplyCalculator {
    /// @notice Calculates current circulating supply of TPI
    /// @return Current circulating supply of TPI
    function getCirculatingSupply() external view returns (uint256);
}

contract TPI is ERC20Permit, Multicall, Ownable {
    error NotManagement();
    error ZeroAddress();

    address public immutable segmentManagement;
    ISupplyCalculator public supplyCalculator;

    constructor(
        string memory name_,
        string memory symbol_,
        address initMintReceiver,
        uint256 initMintAmount,
        IgNFT gNft
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        segmentManagement = gNft.SEGMENT_MANAGEMENT();
        _mint(initMintReceiver, initMintAmount);
    }

    /// @notice         Function to be used for gNFT segment activation
    /// @param account  Address, whose token to be burned
    /// @param amount   Amount to be burned
    function burnFrom(address account, uint256 amount) external {
        if (msg.sender != segmentManagement) revert NotManagement();
        _burn(account, amount);
    }

    /// @notice View function to get current active circulating supply,
    ///         used to calculate price of gNFT segment activation
    /// @return Current circulating supply of TPI
    function getCirculatingSupply() external view returns (uint256) {
        return supplyCalculator.getCirculatingSupply();
    }

    /// @notice                  Sets supplyCalculator
    /// @param supplyCalculator_ Address of actual supply calculator contract
    function setSupplyCalculator(ISupplyCalculator supplyCalculator_) public onlyOwner {
        if(address(supplyCalculator_) == address(0)) revert ZeroAddress();
        supplyCalculator = supplyCalculator_;
    }
}