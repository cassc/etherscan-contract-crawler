// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract IgupBooster is Ownable, EIP712 {
    event Staked(
        address indexed staker,
        uint256 amount,
        uint256 duration,
        uint256 endDate,
        uint256 oldAmount,
        uint256 oldDuration
    );

    event Unstaked(address indexed staker, uint256 amount);

    struct Stake {
        uint256 amount;
        uint256 duration;
        uint256 endDate;
    }

    IERC20 public token;
    address public signer;

    address[] public stakers;
    mapping(address => Stake) internal _stakeOf;
    mapping(bytes => bool) internal _isSignatureUsed;

    function stakeOf(address staker) external view returns (Stake memory) {
        return _stakeOf[staker];
    }

    constructor(IERC20 tokenContract, address signerAddress)
        EIP712("Iguverse", "1")
    {
        token = tokenContract;
        signer = signerAddress;
    }

    function _updateStake(
        uint256 amount,
        uint256 durationDays
    ) internal{
        Stake memory s = _stakeOf[msg.sender];
        require(s.duration <= durationDays, "IgupBooster: New duration can not be lower");
        uint256 endDate = block.timestamp + durationDays * 1 days;
        if(endDate < s.endDate){
            endDate = s.endDate;
        }
        if(s.endDate == 0){
            stakers.push(msg.sender);
        }
        uint256 newAmount = amount + s.amount;
        _stakeOf[msg.sender] = Stake({amount: newAmount, duration: durationDays, endDate: endDate});
        emit Staked(msg.sender, newAmount, durationDays, endDate, s.amount, s.duration);
    }

    function stake(
        uint256 amount,
        uint256 durationDays,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(!_isSignatureUsed[signature], "IgupBooster: Signature already used");
        _isSignatureUsed[signature] = true;
        require(block.timestamp <= deadline, "IgupBooster: Transaction overdue");
        require(durationDays > 0, "IgupBooster: Minimum 1 day duration");

        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "StakeData(address staker,uint256 amount,uint256 durationDays,uint256 deadline)"
                    ),
                    msg.sender,
                    amount,
                    durationDays,
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "IgupBooster: Signature Mismatch"
        );

        require(
            token.balanceOf(msg.sender) >= amount,
            "IgupBooster: Not enought balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "IgupBooster: Allowance not enough"
        );
        token.transferFrom(msg.sender, address(this), amount);

        _updateStake(amount, durationDays);
    }

    function unstake() external {
        Stake memory s = _stakeOf[msg.sender];
        require(
            block.timestamp >= s.endDate,
            "IgupBooster: Stake period is not ended"
        );
        _stakeOf[msg.sender] = Stake({amount: 0, endDate: 0, duration: 0});
        token.transfer(msg.sender, s.amount);
        emit Unstaked(msg.sender, s.amount);
    }

    /// @notice Rewrites Signer Address
    /// @param newSigner new signer's address
    /// @dev All signatures made by the old signer will no longer be valid. Only Owner can execute this function
    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }
}