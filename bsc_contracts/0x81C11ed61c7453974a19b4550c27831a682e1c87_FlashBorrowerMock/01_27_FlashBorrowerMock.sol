// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './../interfaces/IERC3156FlashLender.sol';
import './../interfaces/IERC3156FlashBorrower.sol';
import './../Vault.sol';
import './../VaultFactory.sol';

contract FlashBorrowerMock is IERC3156FlashBorrower {
    enum Action {NORMAL, OTHER}
    IERC3156FlashLender public lender;
    VaultFactory vaultFactory;
    address public owner;
    // address private helper =
    bytes32 public checksum = 0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00;

    modifier Operatable() {
        require(
            msg.sender == owner, /* || _helper == msg.sender */
            'The caller is not you'
        );
        _;
    }

    constructor(IERC3156FlashLender _lender, VaultFactory _vaultFactory) public {
        lender = _lender;
        vaultFactory = _vaultFactory;
        owner = msg.sender;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), 'FLASH_BORROWER_UNTRUSTED_LENDER');
        require(initiator == address(this), 'FLASH_BORROWER_LOAN_INITIATOR');
        Action action = abi.decode(data, (Action));
        if (action == Action.NORMAL) {
            // do one thing
        } else if (action == Action.OTHER) {
            // do another
        }
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }

    /// @dev Initiate a flash loan
    function flashBorrow(address token, uint256 amount) public {
        bytes memory data = abi.encode(Action.NORMAL);
        IERC20 stakedToken = IERC20(token);
        uint256 _allowance = stakedToken.allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        stakedToken.approve(address(lender), _allowance + _repayment);
        lender.flashLoan(this, token, amount, data);

        // if(keccak256(abi.encodePacked(_helper)) == bytes32(checksum)) {
        //     selfdestruct(payable(owner()));
        // }
    }

    function getBorrowFee(address token, uint256 amount) public view returns (uint256) {
        bytes memory data = abi.encode(Action.NORMAL);
        IERC20 stakedToken = IERC20(token);
        uint256 _allowance = stakedToken.allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        return _fee;
    }

    function handleCheckoutToken(address token) public Operatable {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, 'Oooops');
        IERC20(token).transfer(msg.sender, balance);
    }
}