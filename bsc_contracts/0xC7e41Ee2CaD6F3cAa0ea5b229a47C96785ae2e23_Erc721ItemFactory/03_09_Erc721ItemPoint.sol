pragma solidity ^0.8.17;

import '../../DealPoint.sol';

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/// @dev allows to create a transaction detail for the transfer of ERC20 tokens
contract Erc721ItemPoint is DealPoint {
    IERC721 public token;
    uint256 public itemId;
    address public from;
    address public to;
    uint256 public feeEth;

    receive() external payable {}

    constructor(
        address _router,
        address _token,
        uint256 _itemId,
        address _from,
        address _to,
        address _feeAddress,
        uint256 _feeEth
    ) DealPoint(_router, _feeAddress) {
        token = IERC721(_token);
        itemId = _itemId;
        from = _from;
        to = _to;
        feeEth = _feeEth;
    }

    function isComplete() external view override returns (bool) {
        return token.ownerOf(itemId) == address(this);
    }

    function withdraw() external payable {
        /*address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transferFrom(address(this), owner, itemId);*/

        if (isSwapped) {
            require(msg.value >= feeEth);
            payable(feeAddress).transfer(feeEth);
        }

        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transferFrom(address(this), owner, itemId);
    }
}