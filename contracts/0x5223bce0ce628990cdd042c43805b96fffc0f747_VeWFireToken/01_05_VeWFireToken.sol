// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./VeERC20.sol";

interface IRewarder {
    function updateFactor(address, uint256) external;
}

/// @title Vote Escrow WFIRE Token - veWFIRE
/// @author Promethios
/// @notice Infinite supply, used to receive extra farming yields and voting power
contract VeWFireToken is VeERC20("VeWFireToken", "veWFIRE"), Ownable {
    /// @notice rewarders contracts including the BoostedMasterChef contract
    IRewarder[] public rewarders;

    mapping(address => bool) public isOperator;

    event UpdateRewarders(address indexed user, IRewarder[] rewarders);

    /// @dev Creates `_amount` token to `_to`. Must only be called by the owner (VeWFireStaking)
    /// @param _to The address that will receive the mint
    /// @param _amount The amount to be minted
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /// @dev Destroys `_amount` tokens from `_from`. Callable only by the owner (VeWFireStaking)
    /// @param _from The address that will burn tokens
    /// @param _amount The amount to be burned
    function burnFrom(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    function setOperator(address operator, bool _is) external onlyOwner {
        isOperator[operator] = _is;
    }

    /// @dev Sets the address of the master chef contract this updates
    /// @param _rewarders the addresses of Rewarder contracts
    function setRewarders(IRewarder[] calldata _rewarders) external {
        require(isOperator[msg.sender], "Not operator");

        delete rewarders;
        // We allow 0 address here if we want to disable the callback operations
        for (uint256 index = 0; index < _rewarders.length; index++) {
            rewarders.push(_rewarders[index]);
        }

        emit UpdateRewarders(_msgSender(), rewarders);
    }

    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        for (uint256 index = 0; index < rewarders.length; index++) {
            IRewarder rewarder = rewarders[index];
            if (address(rewarder) != address(0)) {
                rewarder.updateFactor(_account, _newBalance);
            }
        }
    }

    function renounceOwnership() public override onlyOwner {
        revert("VeWFireToken: Cannot renounce, can only transfer ownership");
    }
}