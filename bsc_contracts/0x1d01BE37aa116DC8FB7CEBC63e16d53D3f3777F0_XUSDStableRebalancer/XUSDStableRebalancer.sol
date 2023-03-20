/**
 *Submitted for verification at BscScan.com on 2023-03-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param tokenToBorrow The loan currency, must be an approved stable coin.
     * @param tokenToRepay The repayment currency, must be an approved stable coin.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address tokenToBorrow,
        address tokenToRepay,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IFlashLoanProvider {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param tokenToBorrow The loan currency, must be an approved stable coin
     * @param tokenToRepay The Repayment currency, must be an approved stable coin
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IFlashBorrower receiver,
        address tokenToBorrow,
        address tokenToRepay,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IEllipsis {
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
}

contract XUSDStableRebalancer is IFlashBorrower {

    IFlashLoanProvider provider = IFlashLoanProvider(0x7FEeb737D07F24eAa76F146295f0f3D4ad9c2Adc);

    IEllipsis router = IEllipsis(0x160CAed03795365F3A589f10C379FfA7d75d4E76);

    address XUSD = 0x324E8E649A6A3dF817F97CdDBED2b746b62553dD;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address USDT = 0x55d398326f99059fF775485246999027B3197955;
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    // Callback Success
    bytes32 public constant CALLBACK_SUCCESS = keccak256('ERC3156FlashBorrower.onFlashLoan');

    address owner;
    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function withdrawToken(address token) external OnlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function withdrawNative() external OnlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function changeOwner(address newOwner) external OnlyOwner {
        owner = newOwner;
    }

    receive() external payable {}

    function convertToInt(address token) public view returns (int128) {
        return token == BUSD ? int128(0) : token == USDC ? int128(1) : token == USDT ? int128(2) : int128(11);
    }

    function trigger(uint amount, address tokenToBorrow, address tokenToRepay) external OnlyOwner {
        provider.flashLoan(IFlashBorrower(address(this)), tokenToBorrow, tokenToRepay, amount, '');
    }

    function onFlashLoan(
        address initiator,
        address tokenToBorrow,
        address tokenToRepay,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(tx.origin == owner, 'Only Owner');
        initiator;
        data;
        
        IERC20(tokenToBorrow).approve(address(router), amount);
        router.exchange(
            convertToInt(tokenToBorrow),
            convertToInt(tokenToRepay),
            amount,
            0
        );

        IERC20(tokenToRepay).transfer(
            address(provider),
            amount + fee
        );

        return CALLBACK_SUCCESS;
    }


}