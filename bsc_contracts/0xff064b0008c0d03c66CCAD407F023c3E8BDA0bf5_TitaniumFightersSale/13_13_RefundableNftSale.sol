// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RefundableNftSale is
    Ownable,
    Pausable,
    ReentrancyGuard,
    IERC721Receiver
{
    using SafeERC20 for IERC20;

    IERC721 public nftToken;
    IERC20 public paymentToken;

    uint256 public startTime;

    uint256 public price;
    uint256 public refundTimeLimit;

    mapping(uint256 => bool) public isTokenAvailable;
    uint256[] public availableTokens;

    struct UserClaims {
        uint256 amount;
        uint256 withdrawn;
    }
    mapping(address => UserClaims) public userClaims;
    uint256 public totalClaims;

    struct RefundableToken {
        uint256 tokenId;
        address buyer;
        uint256 price;
        uint256 boughtAt;
    }
    mapping(uint256 => RefundableToken) public refundableTokens;

    mapping(uint256 => bool) public isTokenSold;
    uint256[] public soldTokens;

    mapping(uint256 => bool) public isTokenRefunded;
    uint256[] public refundedTokens;

    event TokenListed(uint256 tokenId);

    event PriceChange(uint256 from, uint256 to);

    event RefundTimeChanged(uint256 fromTime, uint256 toTime);
    event StartTimeChanged(uint256 fromTime, uint256 toTime);

    event TokenSold(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price,
        uint256 boughtAt
    );

    event TokenRefunded(
        uint256 indexed tokenId,
        address indexed refunder,
        uint256 price,
        uint256 refundedAt
    );

    event Claimed(address indexed claimer, uint256 amount, uint256 claimedAt);

    constructor(
        address _nftToken,
        address _paymentToken,
        uint256 _startTime,
        uint256 _price,
        uint256 _refundTimeLimit
    ) {
        nftToken = IERC721(_nftToken);
        paymentToken = IERC20(_paymentToken);
        startTime = _startTime;
        price = _price;
        refundTimeLimit = _refundTimeLimit;
    }

    //////////
    // Getters
    //////////
    function getAvailableTokens() external view returns (uint256[] memory) {
        return availableTokens;
    }

    function getAvailableTokensLength() external view returns (uint256) {
        return availableTokens.length;
    }

    function getRefundedTokens() external view returns (uint256[] memory) {
        return refundedTokens;
    }

    function getRefundedTokensLength() external view returns (uint256) {
        return refundedTokens.length;
    }

    function getSoldTokens() external view returns (uint256[] memory) {
        return soldTokens;
    }

    function getSoldTokensLength() external view returns (uint256) {
        return soldTokens.length;
    }

    //////////
    // Setters
    //////////

    function setRefundTimeLimit(uint256 _refundTimeLimit) external onlyOwner {
        emit RefundTimeChanged(refundTimeLimit, _refundTimeLimit);

        require(_refundTimeLimit > block.timestamp, "invalid time");

        refundTimeLimit = _refundTimeLimit;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        emit StartTimeChanged(startTime, _startTime);

        startTime = _startTime;
    }

    function setPrice(uint256 _price) external onlyOwner {
        emit PriceChange(price, _price);

        price = _price;
    }

    //////////
    // Mark for sale
    //////////
    function listTokens(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            if (!isTokenAvailable[_tokenId]) {
                isTokenAvailable[_tokenId] = true;
                availableTokens.push(_tokenId);

                emit TokenListed(_tokenId);
            }
        }
    }

    function buyToken() external nonReentrant whenNotPaused {
        require(availableTokens.length > 0, "Not tokens available");
        require(block.timestamp > startTime, "Not started yet");

        // get next token randomly
        uint256 nextTokenIndex = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    block.timestamp
                )
            )
        ) % availableTokens.length;
        uint256 nextToken = availableTokens[nextTokenIndex];

        require(isTokenAvailable[nextToken], "Token not available");
        isTokenAvailable[nextToken] = false;

        // remove the randomly selected token
        availableTokens[nextTokenIndex] = availableTokens[
            availableTokens.length - 1
        ];
        availableTokens.pop();

        refundableTokens[nextToken] = RefundableToken(
            nextToken,
            msg.sender,
            price,
            block.timestamp
        );
        soldTokens.push(nextToken);
        isTokenSold[nextToken] = true;

        paymentToken.safeTransferFrom(msg.sender, address(this), price);
        nftToken.safeTransferFrom(address(this), msg.sender, nextToken);

        emit TokenSold(nextToken, msg.sender, price, block.timestamp);
    }

    function refundToken(uint256 _tokenId) external nonReentrant whenNotPaused {
        RefundableToken memory _token = refundableTokens[_tokenId];

        require(_token.price > 0, "Cannot refund 0 price");
        require(refundTimeLimit > block.timestamp, "Refund limit passed");

        nftToken.safeTransferFrom(msg.sender, address(this), _tokenId);

        userClaims[msg.sender].amount += _token.price;
        totalClaims += _token.price;

        isTokenRefunded[_tokenId] = true;
        refundedTokens.push(_tokenId);

        delete refundableTokens[_tokenId];

        emit TokenRefunded(_tokenId, msg.sender, _token.price, block.timestamp);
    }

    function claim() external nonReentrant whenNotPaused {
        require(block.timestamp > refundTimeLimit, "Refunds not over");

        uint256 amountToTransfer = claimable(msg.sender);
        require(amountToTransfer > 0, "Nothing to claim");

        userClaims[msg.sender].withdrawn = userClaims[msg.sender].amount;
        totalClaims -= amountToTransfer;

        paymentToken.safeTransfer(msg.sender, amountToTransfer);

        emit Claimed(msg.sender, amountToTransfer, block.timestamp);
    }

    function claimable(address _address) public view returns (uint256) {
        return userClaims[_address].amount - userClaims[_address].withdrawn;
    }

    //////////
    // Pause
    //////////
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //////////
    // Token withdrawals
    //////////
    function withdrawERC20(
        IERC20 _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (_amount == 0) {
            _tokenAddress.safeTransfer(
                _to,
                _tokenAddress.balanceOf(address(this))
            );
        } else {
            _tokenAddress.safeTransfer(_to, _amount);
        }
    }

    function withdrawERC721(
        IERC721 _tokenAddress,
        address _to,
        uint256 _tokenId
    ) external onlyOwner {
        _tokenAddress.safeTransferFrom(address(this), _to, _tokenId);
    }

    function withdrawERC721Multiple(
        IERC721 _tokenAddress,
        address _to,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _tokenAddress.safeTransferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}