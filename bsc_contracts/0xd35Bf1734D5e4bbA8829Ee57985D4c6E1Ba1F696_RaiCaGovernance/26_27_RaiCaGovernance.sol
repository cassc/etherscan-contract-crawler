// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC721DividendPaying.sol";

contract RaiCaGovernance is
    ERC721PresetMinterPauserAutoId,
    IERC721DividendPaying
{
    using SafeERC20 for IERC20;
    using Address for address;
    using Strings for uint256;

    uint256 private _totalSupply;
    uint256 private _vault;
    uint256 private _dividendPerShare;

    mapping(address => int256) private _dividendCorrections;
    mapping(address => uint256) private _withdrawnDividends;
    string public baseURI;
    string public baseExtension = ".json";

    IERC20 public rewardToken;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _rewardToken
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _uri) {
        _totalSupply = 0;
        _dividendPerShare = 0;
        rewardToken = IERC20(_rewardToken);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    // OnlyAdmin functions

    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    function setRewardToken(address _rewardToken) public onlyAdmin {
        rewardToken = IERC20(_rewardToken);
    }

    function distributeDividends(uint256 _amount) external override {
        require(
            totalSupply() > 0,
            "ERC721DividentPaying: total token supply is 0"
        );
        require(_amount != 0, "ERC721DividentPaying: amount is 0");

        rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);

        _dividendPerShare += _amount / totalSupply();
        _vault += _amount;

        emit DividendsDistributed(_msgSender(), _amount);
    }

    function withdrawDividend() external override {
        require(
            !_msgSender().isContract(),
            "ERC721DividentPaying: withdrawal from contract is not allowed"
        );

        uint256 withdrawableDividend = withdrawableDividendOf(_msgSender());
        require(withdrawableDividend != 0, "ERC721DividentPaying: no dividend");

        _withdrawnDividends[_msgSender()] += withdrawableDividend;

        rewardToken.safeTransfer(_msgSender(), withdrawableDividend);

        _vault -= withdrawableDividend;

        emit DividendWithdrawn(_msgSender(), withdrawableDividend);
    }

    function dividendOf(address owner) public view override returns (uint256) {
        return withdrawableDividendOf(owner);
    }

    function withdrawableDividendOf(
        address owner
    ) public view override returns (uint256) {
        return accumulativeDividendOf(owner) - _withdrawnDividends[owner];
    }

    function accumulativeDividendOf(
        address owner
    ) public view override returns (uint256) {
        uint256 totalDividendOfOwner = _dividendPerShare * balanceOf(owner);
        int256 accumulativeDividendOfOwner = int256(totalDividendOfOwner) +
            _dividendCorrections[owner];

        require(accumulativeDividendOfOwner >= 0);

        return uint256(accumulativeDividendOfOwner);
    }

    function withdrawnDividendOf(
        address owner
    ) public view override returns (uint256) {
        return _withdrawnDividends[owner];
    }

    function vault() public view override returns (uint256) {
        return _vault;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address to, uint256 tokenID) internal override {
        super._mint(to, tokenID);

        _totalSupply++;

        if (_dividendPerShare > 0) {
            _dividendCorrections[to] -= int256(_dividendPerShare);
        }
    }

    function _burn(uint256 tokenID) internal override {
        address owner = ownerOf(tokenID);

        super._burn(tokenID);

        _totalSupply--;

        if (_dividendPerShare > 0) {
            _dividendCorrections[owner] += int256(_dividendPerShare);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenID
    ) internal override {
        super._transfer(from, to, tokenID);

        if (_dividendPerShare > 0 && !from.isContract() && !to.isContract()) {
            int256 correction = int256(_dividendPerShare);

            _dividendCorrections[from] += correction;
            _dividendCorrections[to] -= correction;
        }
    }
}