// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721Releasable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @author lwx12525
 * @dev For cqone.art
 */
abstract contract ERC721Releasable is ERC721Enumerable, Ownable, IERC721Releasable {
    /// @dev 每个受益人领取的金额
    mapping(address => uint256) private _released;
    /// @dev 每个受益人已经领取的份数
    mapping(address => uint256) private _releasedShares;
    /// @dev 每个tokenId的实际受益人
    mapping(uint256 => address) private _releasedRecord;

    /// @dev 总支出
    uint256 private _totalReleased;
    /// @dev 总份数
    uint256 private _totalShares;

    event PaymentReceived(address from, uint256 amount);
    event PaymentReleased(address to, uint256 amount);

    /**
     * @dev See {IERC721Releasable-setTotalShares}.
     */
    function setTotalShares(uint256 newValue) public override onlyOwner {
        _totalShares = newValue;
    }

    /**
     * @dev See {IERC721Releasable-receive}.
     */
    receive() external payable virtual override {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev See {IERC721Releasable-totalReceived}.
     */
    function totalReceived() public view override returns (uint256) {
        return address(this).balance + _totalReleased;
    }

    /**
     * @dev See {IERC721Releasable-totalShares}.
     */
    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev See {IERC721Releasable-totalReleased}.
     */
    function totalReleased() public view override returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev See {IERC721Releasable-released}.
     */
    function released(address account) public view override returns (uint256) {
        return _released[account];
    }

    /**
     * @dev See {IERC721Releasable-releasedShares}.
     */
    function releasedShares(address account) public view override returns (uint256) {
        return _releasedShares[account];
    }

    /**
     * @dev See {IERC721Releasable-releasedRecord}.
     */
    function releasedRecord(uint256 tokenId) public view override returns (address) {
        return _releasedRecord[tokenId];
    }

    /**
     * @dev See {IERC721Releasable-releasable}.
     */
    function releasable(address account) public view override returns (uint256) {
        uint256 shares = releasableShares(account);
        if (shares == 0) {
            return 0;
        }
        return (totalReceived() * shares) / totalShares() - released(account);
    }

    /**
     * @dev See {IERC721Releasable-releasableShares}.
     */
    function releasableShares(address account) public view override returns (uint256) {
        return balanceOf(account) - releasedShares(account);
    }

    /**
     * @dev See {IERC721Releasable-release}.
     */
    function release() public override {
        require(balanceOf(_msgSender()) > 0, "BondNFT: account has no nft");
        require(totalReceived() > 0, "BondNFT: contract has no fund");

        uint256 payment = releasable(_msgSender());
        require(payment != 0, "BondNFT: account is not due payment");

        _totalReleased += payment;
        unchecked {
            _released[_msgSender()] += payment;
        }

        // 遍历用户tokens，从_releasedRecord中找出没有提取的token
        // 找到之后记录提取人信息, 最后记录本次提取的份数
        for (uint i = 0; i < balanceOf(_msgSender()); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            if (releasedRecord(tokenId) == address(0)) {
                _releasedRecord[tokenId] = _msgSender();
            }
        }
        uint256 shares = releasableShares(_msgSender());
        unchecked {
            _releasedShares[_msgSender()] += shares;
        }

        Address.sendValue(payable(_msgSender()), payment);
        emit PaymentReleased(_msgSender(), payment);
    }
}