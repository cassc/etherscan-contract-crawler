// SPDX-License-Identifier: MIT
// DumplingZai v69696969 
// "I smash keyboards and vomit smart contracts"

pragma solidity ^0.8.0;

import "./2.IERC20.sol";
import "./3.Ownable.sol";
import "./8.IERC721Receiver.sol";
import "./9.AccessControl.sol";
import "./21.IUniswapV2Router02.sol";


contract EGGPOT_Main is Ownable, IERC721Receiver, AccessControl {
    IUniswapV2Router02 public uniswapV2Router;
    address[] public tokenAddress;
    mapping(address => bool) public tokenToSwap;

    bytes32 public constant AUTOMATOR_ROLE = keccak256("AUTOMATOR_ROLE");

    uint256 public estimatedGas = 200000;
    uint256 public gasPrice = 70 * 1e9; // 70 Gwei in Wei
    uint256 public gasCostInWei = estimatedGas * gasPrice;

    enum Status { NotStarted, AcceptingTokens, SwappingMode, ClaimMode, LuckyDraw, Reset }
    Status public status;

    address[] public claimable;
    mapping(address => mapping(uint256 => bool)) public hasClaimed;

    uint256 public currentRound = 0;
    mapping(address => mapping(uint256 => uint256)) public participantEntries;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        status = Status.NotStarted;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(AUTOMATOR_ROLE, msg.sender);
    }

    modifier onlyOwnerOrAutomator() {
        require(hasRole(AUTOMATOR_ROLE, msg.sender) || owner() == msg.sender, "Caller is not the owner or the automator");
        _;
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Function to update the estimated gas cost for a swap
    function setEstimatedGas(uint256 _estimatedGas, uint256 _gasPrice) external onlyOwnerOrAutomator {
        estimatedGas = _estimatedGas;
        gasPrice = _gasPrice;
        gasCostInWei = estimatedGas * gasPrice;
    }

    // ERC721Receiver function to receive NFTs
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Function to store claimable amounts (address only) 
    function storeClaimable(address[] calldata _addresses) external onlyOwnerOrAutomator {
        for (uint256 i = 0; i < _addresses.length; i++) {
            claimable.push(_addresses[i]);
        }
    }

    // Function to change status of the platform
    function changeStatus(Status _status) external onlyOwnerOrAutomator {
        status = _status;
    }

    // Function to claim ETH (address n amount)
    function claimEth(address payable _address, uint256 _amount, uint256 round) external {
        require(status == Status.ClaimMode, "Not in Claim Mode");
        bool isClaimable = false;
        
        for (uint i = 0; i < claimable.length; i++) {
            if (claimable[i] == _address) {
                isClaimable = true;
                break;
            }
        }
        
        require(isClaimable, "Address is not in the claimable list");
        require(!hasClaimed[_address][round], "Address has already claimed");

        // Mark address as having claimed
        hasClaimed[_address][round] = true;

        // Transfer ETH
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function swapTokensForEth(address token) private onlyOwnerOrAutomator returns (bool) {
        require(status == Status.SwappingMode, "Not in Swapping Mode");
        uint256 contractTokenBalance = IERC20(token).balanceOf(address(this));
        if (contractTokenBalance == 0 || token == address(0)) {
            return false;
        }

        bool approveSuccess = IERC20(token).approve(address(uniswapV2Router), contractTokenBalance);
        require(approveSuccess, "Token approval failed");

        address[] memory path = getPathForTokenToETH(token);
        uint[] memory amountsOut = uniswapV2Router.getAmountsOut(contractTokenBalance, path);
        uint estimatedOutput = amountsOut[amountsOut.length - 1];

        if (estimatedOutput >= gasCostInWei) {
            uniswapV2Router.swapExactTokensForETH(
                contractTokenBalance,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
            return true;
        }

        return false;
    }

    function swapTokensForEthBulk() public onlyOwnerOrAutomator {
        require(status == Status.SwappingMode, "Not in Swapping Mode");
        require(tokenAddress.length > 0, "No tokens to swap");

        for(uint i = 0; i < tokenAddress.length; i++) {
            if(tokenToSwap[tokenAddress[i]]) {
                swapTokensForEth(tokenAddress[i]);
            }
        }
    }

    function sendTokensBulk(uint256[] memory tokenAmounts, address[] memory tokens) public {
        require(status == Status.AcceptingTokens, "Not in Accepting Tokens Mode");
        require(tokenAmounts.length == tokens.length, 'Arrays must be of equal length');
        for(uint i = 0; i < tokenAmounts.length; i++) {
            IERC20(tokens[i]).transferFrom(msg.sender, address(this), tokenAmounts[i]);
        }
    }

    function receiveTokenAddresses(address[] memory newTokenAddresses) public onlyOwnerOrAutomator {
        for(uint i = 0; i < newTokenAddresses.length; i++) {
            if (!tokenToSwap[newTokenAddresses[i]]) {
                tokenToSwap[newTokenAddresses[i]] = true;
                tokenAddress.push(newTokenAddresses[i]);
            }
        }
    }

    function withdrawTokens(address token, address to) public onlyOwnerOrAutomator {
        uint256 contractTokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, contractTokenBalance);
    }

    function getPathForTokenToETH(address token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();

        return path;
    }

    // Function to get participant entries
    function getParticipantEntries(address participant) external view returns (uint256) {
        return participantEntries[participant][currentRound];
    }

    function incrementRound() external onlyOwnerOrAutomator {
        currentRound++;
    }
}
