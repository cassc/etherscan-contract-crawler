// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ASMBrainsASTOAirdrop is Pausable, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    IERC721 public immutable brain;
    uint256 public immutable tokenAmountPerBrain;

    mapping(uint256 => bool) public claimed;
    uint256 public totalBrainsClaimed;

    event TokenClaimed(address indexed recipient, uint256 brainId, uint256 tokenAmount);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    /**
     * @notice Initialize the contract
     * @param multisig Multisig address as the contract owner
     * @param _token $ASTO contract address
     * @param _brain ASM Brains contract address
     * @param _tokenAmountPerBrain $ASTO token amount to be airdropped to each ASM Brain
     */
    constructor(
        address multisig,
        IERC20 _token,
        IERC721 _brain,
        uint256 _tokenAmountPerBrain
    ) {
        require(address(multisig) != address(0), "invalid multisig address");
        require(address(_token) != address(0), "invalid token address");
        require(address(_brain) != address(0), "invalid brain address");

        token = _token;
        brain = _brain;
        totalBrainsClaimed = 0;
        tokenAmountPerBrain = _tokenAmountPerBrain;
        _pause();
        _transferOwnership(multisig);
    }

    /**
     * @notice Claim airdrop based on ASM Brain token ids
     * @param brainIds ASM Brain token ids to claim for
     */
    function claim(uint256[] calldata brainIds) external {
        require(token.balanceOf(address(this)) >= tokenAmountPerBrain * brainIds.length, "insufficient token balance");
        require(!paused(), "Claim() is not enabled");

        for (uint256 i = 0; i < brainIds.length; i++) {
            require(!claimed[brainIds[i]], "Airdrop already claimed");
            require(brain.ownerOf(brainIds[i]) == msg.sender, "Only owner can claim");

            claimed[brainIds[i]] = true;
            emit TokenClaimed(msg.sender, brainIds[i], tokenAmountPerBrain);
        }

        totalBrainsClaimed += brainIds.length;
        token.safeTransfer(msg.sender, brainIds.length * tokenAmountPerBrain);
    }

    /**
     * @notice Withdraw any token left in the contract to multisig
     * @param _token ERC20 token contract address to withdraw
     * @param amount Token amount to withdraw
     */
    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        require(_token != address(0), "invalid token address");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(amount <= balance, "amount should not exceed balance");
        IERC20(_token).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Pause the claiming process
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the claiming process
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}