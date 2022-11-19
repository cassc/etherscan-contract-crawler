//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

interface IColdStaking {
    function balanceOf(address account) external view returns (uint256);
}

/// @title SRGToken
/// @author IllumiShare SRG
/// @notice ERC20 SRG Token
// We are using Gnosis safe smart contract to be owner of this contract
contract SrgToken is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 7951696555 ether;
    uint256 public supply;
    uint256 public transferFee;
    address public coldStakingAddress;

    event TransferFeeSet(uint256 fee);

    /* ========== CONSTRUCTOR ========== */
    constructor(address multiSigWallet, address _coldStakingAddress)
        ERC20("IllumiShare SRG", "SRG")
    {
        supply = 0 ether;
        transferFee = 18;
        // We are going to transfer to a GNSOSIS SAFE to be sure
        transferOwnership(multiSigWallet);
        coldStakingAddress = _coldStakingAddress;
        _mint(multiSigWallet, MAX_SUPPLY);
    }

    /* ========== OWNER FUNCTIONS ========== */

    /**
     * @notice Burns SRG Tokens
     *
     * @param amount - Amount of tokens to be burned
     */
    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(msg.sender, amount);

        return (true);
    }

    /**
     * @notice Sets the tax fee on transfers and transferFroms
     *
     * @param fee - SRG token Transaction fee
     */
    function setTransferFee(uint256 fee) external onlyOwner returns (bool) {
        // RANGE is 0.018% to 0.18%
        // 1000 = 100% // WE DIVIDE BY 1000
        // 18 = 0.018%
        // 180 = 0.18%

        require(fee >= 18, "Fee cant be lower than 0.018 percent");
        require(fee <= 180, "Fee can't be higher than 0.18 percent");

        transferFee = fee;

        emit TransferFeeSet(fee);
        return (true);
    }

    /**
     * @notice Sets coldStaking Address
     *
     * @param _coldStakingAddress - Address of the cold Staking contract
     */
    function setColdStakingAddress(address _coldStakingAddress)
        external
        onlyOwner
    {
        coldStakingAddress = _coldStakingAddress;
    }

    /**
     * @notice Withdraw any IERC20 tokens accumulated in this contract
     *
     * @param token - Address of token contract
     */
    ///
    function withdrawTokens(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    /* ========= VIEWS ========= */

    function getTransferFee() external view returns (uint256) {
        return (transferFee);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (_msgSender() == owner()) {
            _transfer(_msgSender(), to, amount);
        } else {
            _transferWithFees(_msgSender(), to, amount);
        }

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transferWithFees(from, to, amount);

        uint256 currentAllowance = allowance(from, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(from, _msgSender(), currentAllowance - amount);

        emit Transfer(from, to, amount);

        return true;
    }

    function _transferWithFees(
        address from,
        address to,
        uint256 amount
    ) private {
        require(balanceOf(from) >= amount, "Balance is too low");
        uint256 fee = amount.mul(transferFee).div(1000);
        uint256 afterFee = amount.sub(fee);

        _transfer(from, to, afterFee);
        _transfer(from, address(this), fee);
    }

    /**
     * @notice Before hook to effectively lock tokens inside user account when he has colstaked
     
     *
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal virtual override {
        // console.log(IColdStaking(coldStakingAddress).balanceOf(from));

        if (from != address(0)) {
            require(
                balanceOf(from) >=
                    IColdStaking(coldStakingAddress).balanceOf(from) + amount,
                "Not enough unlocked"
            );
        }
    }
}