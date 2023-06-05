// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVester {
    function vest(
        bool vest,
        address account,
        uint256 amount
    ) external;
}

interface IDistributer {
    function burn(uint256 amount) external;
}

/// Contract for moving users GRO tokens into a vesting position. Allows user to add to their
///  current vesting position (or creating a new) by vurning a set amount of gro tokens. The
///  vest to burn ratio is 1 : 1
contract GROBurner is Ownable {
    using SafeERC20 for IERC20;

    address public vester;
    address public distributer;
    address public immutable groToken;

    event LogNewBurn(address indexed user, uint256 amount);
    event LogNewDistributer(address distributer);
    event LogNewVester(address vester);

    constructor(address _vester, address _groToken) {
        vester = _vester;
        emit LogNewVester(_vester);
        groToken = _groToken;
    }

    /// @notice Set new vesting contract, this contract needs to be listed
    ///  as a vester in the target contract
    /// @param _vester Address of new vesting contract
    function setVester(address _vester) external onlyOwner {
        vester = _vester;
        emit LogNewVester(_vester);
    }

    /// @notice Set new distributer contract, this contract needs to be listed
    ///  as a burner in the target contract
    /// @param _distributer Address of new distributer contract
    function setDistributer(address _distributer) external onlyOwner {
        distributer = _distributer;
        emit LogNewDistributer(_distributer);
    }

    /// @notice Lets user move their tokens to new or existing vesting position
    /// @param amount amount the user wishes to move
    function reVest(uint256 amount) external {
        IERC20 _gro = IERC20(groToken);
        _gro.safeTransferFrom(msg.sender, address(this), amount);
        IDistributer(distributer).burn(amount);
        IVester(vester).vest(true, msg.sender, amount);
        emit LogNewBurn(msg.sender, amount);
    }
}