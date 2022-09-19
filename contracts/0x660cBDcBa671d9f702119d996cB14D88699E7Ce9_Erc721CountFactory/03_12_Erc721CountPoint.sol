pragma solidity ^0.8.17;

import '../../DealPoint.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/// @dev позволяет создавать деталь сделки по трансферу ERC20 токена // allows to create a transaction detail for the transfer of ERC20 tokens
contract Erc721CountPoint is DealPoint {
    IERC721Enumerable public token;
    uint256 public needCount;
    address public from;
    address public to;
    uint256 public feeEth;

    receive() external payable {}

    constructor(
        address _router,
        address _token,
        uint256 _needCount,
        address _from,
        address _to,
        address _feeAddress,
        uint256 _feeEth
    ) DealPoint(_router, _feeAddress) {
        token = IERC721Enumerable(_token);
        needCount = _needCount;
        from = _from;
        to = _to;
        feeEth = _feeEth;
        require(
            token.supportsInterface(type(IERC721Enumerable).interfaceId),
            'interface does not supports'
        );
    }

    function isComplete() external view override returns (bool) {
        return token.balanceOf(address(this)) >= needCount;
    }

    function withdraw() external payable {
        if (isSwapped) {
            require(msg.value >= feeEth);
            payable(feeAddress).transfer(feeEth);
        }
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        uint256 count = token.balanceOf(address(this));
        for (uint256 i = 0; i < count; ++i) {
            token.transferFrom(
                address(this),
                owner,
                token.tokenOfOwnerByIndex(owner, 0)
            );
        }
    }

    function withdraw(uint256 tokenId) external {
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transferFrom(address(this), owner, tokenId);
    }
}