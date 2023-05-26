// SPDX-License-Identifier: MIT

/*
 * Created by Eiba (@eiba8884)
 */
/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import "./libs/ProviderTokenA1.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract pNounsContractFilter is ProviderTokenA1, AccessControlEnumerable {
    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");
    // address public admin; // コントラクト管理者。オーナーか管理者がset系メソッドを実行可能

    IContractAllowListProxy public cal;
    uint256 public calLevel = 1;

    mapping(address => bool) public isPNounsMarketplaces; // approveを許可するコントラクトアドレス

    // uint256 constant unixtime_20230101 = 1672498800;

    constructor(
        IAssetProvider _assetProvider,
        string memory _title,
        string memory _shortTitle,
        address[] memory _administrators
    ) ProviderTokenA1(_assetProvider, _title, _shortTitle) {
        _setRoleAdmin(CONTRACT_ADMIN, CONTRACT_ADMIN);

        for (uint256 i = 0; i < _administrators.length; i++) {
            _setupRole(CONTRACT_ADMIN, _administrators[i]);
        }
    }

    ////////// modifiers //////////
    modifier onlyAdminOrOwner() {
        require(
            hasAdminOrOwner(),
            "caller is not the admin"
        );
        _;
    }

    ////////// internal functions start //////////
    function hasAdminOrOwner() internal view returns (bool) {
        return owner() == _msgSender() || hasRole(CONTRACT_ADMIN, _msgSender());
    }

    ////////// onlyOwner functions start //////////
    function setAdminRole(address[] memory _administrators)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < _administrators.length; i++) {
            _grantRole(CONTRACT_ADMIN, _administrators[i]);
        }
    }

    function revokeAdminRole(address[] memory _administrators)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < _administrators.length; i++) {
            _revokeRole(CONTRACT_ADMIN, _administrators[i]);
        }
    }

    ////////////// CAL 関連 ////////////////
    function setCalContract(IContractAllowListProxy _cal)
        external
        onlyAdminOrOwner
    {
        cal = _cal;
    }

    function setCalLevel(uint256 _value) external onlyAdminOrOwner {
        calLevel = _value;
    }

    // overrides
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        // 2023-01-01 までは販売を制限      ＊ 任意タイミングで変更するため、calLevel=0で対応
        // require(
        //     block.timestamp > unixtime_20230101,
        //     "cant sale on markets until 2023/1/1."
        // );

        // calLevel=0は calProxyに依存せずにfalseにする
        if (calLevel == 0) {
            revert("cant trade in marcket places");
        }

        if (address(cal) != address(0)) {
            require(
                cal.isAllowed(operator, calLevel) == true,
                "address no list"
            );
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        // 2023-01-01 までは販売を制限      ＊ 任意タイミングで変更するため、calLevel=0で対応
        // require(
        //     block.timestamp > unixtime_20230101,
        //     "cant sale on markets until 2023/1/1."
        // );

        // calLevel=0は calProxyに依存せずにfalseにする
        if (calLevel == 0) {
            revert("cant trade in marcket places");
        }

        if (address(cal) != address(0)) {
            require(cal.isAllowed(to, calLevel) == true, "address no list");
        }
        super.approve(to, tokenId);
    }

    function setPNounsMarketplace(address _marketplace, bool _allow)
        public
        onlyAdminOrOwner
    {
        isPNounsMarketplaces[_marketplace] = _allow;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {

        // 登録済みアドレスはOK
        if(isPNounsMarketplaces[operator]){
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC721AP2P)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            ERC721A.supportsInterface(interfaceId);
    }
}