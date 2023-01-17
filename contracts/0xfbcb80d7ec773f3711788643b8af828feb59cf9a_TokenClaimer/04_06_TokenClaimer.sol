// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/BoringOwnable.sol";
import "interfaces/IBentoBoxV1.sol";

contract TokenClaimer is BoringOwnable {
    mapping(address => mapping(IERC20 => uint256)) public amounts;
    mapping(address => bool) public claimed;
    address[] public masterContracts;

    IBentoBoxV1 public degenBox;
    IERC20[] public tokens;

    constructor(IBentoBoxV1 _degenBox, address[] memory _masterContracts) {
        degenBox = _degenBox;

        for (uint256 i = 0; i < _masterContracts.length; i++) {
            masterContracts.push(_masterContracts[i]);
        }
    }

    function getMasterContracts() external view returns (address[] memory) {
        return masterContracts;
    }

    function addToken(IERC20 _token) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != _token, "already added");
        }
        tokens.push(_token);
    }

    function setClaim(
        address user,
        IERC20 _token,
        uint256 amount
    ) external onlyOwner {
        require(amounts[user][_token] == 0);
        amounts[user][_token] = amount;
    }

    function claim() external {
        require(!claimed[msg.sender], "already claimed");
        claimed[msg.sender] = true;

        for (uint256 i = 0; i < masterContracts.length; i++) {
            require(!degenBox.masterContractApproved(masterContracts[i], msg.sender), "mastercontract still approved");
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[msg.sender][token];

            if (amount == 0) {
                continue;
            }

            amounts[msg.sender][token] = 0;

            IBentoBoxV1(degenBox).withdraw(token, address(this), msg.sender, amount, 0);
        }
    }

    /// emergency purpose
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory result) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = to.call{value: value}(data);
    }
}