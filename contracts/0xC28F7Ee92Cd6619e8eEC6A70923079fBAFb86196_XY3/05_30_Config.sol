pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./IConfig.sol";


abstract contract Config is
    AccessControl,
    ERC721Holder,
    Pausable,
    ReentrancyGuard,
    IConfig
{
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER");

    
    address public adminFeeReceiver;

    
    uint256 public override maxBorrowDuration = 365 days;
    uint256 public override minBorrowDuration = 1 days;

    
    uint16 public override adminShare = 25;
    uint16 public constant HUNDRED_PERCENT = 10000;

    
    mapping(address => bool) private erc20Permits;

    
    mapping(address => bool) private erc721Permits;


    
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        adminFeeReceiver = admin;
    }

    
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    
    function updateMaxBorrowDuration(uint256 _newMaxBorrowDuration)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(
            _newMaxBorrowDuration >= minBorrowDuration,
            "Invalid duration"
        );
        if(maxBorrowDuration != _newMaxBorrowDuration) {
            maxBorrowDuration = _newMaxBorrowDuration;
            emit MaxBorrowDurationUpdated(_newMaxBorrowDuration);
        }
    }

    
    function updateMinBorrowDuration(uint256 _newMinBorrowDuration)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(
            _newMinBorrowDuration <= maxBorrowDuration,
            "Invalid duration"
        );
        if(minBorrowDuration != _newMinBorrowDuration) {
            minBorrowDuration = _newMinBorrowDuration;
            emit MinBorrowDurationUpdated(_newMinBorrowDuration);
        }
    }

    
    function updateAdminShare(uint16 _newAdminShare)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(
            _newAdminShare <= HUNDRED_PERCENT,
            "basis points > 10000"
        );
        if(adminShare != _newAdminShare) {
            adminShare = _newAdminShare;
            emit AdminFeeUpdated(_newAdminShare);
        }
    }

    
    function updateAdminFeeReceiver(address _newAdminFeeReceiver)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(_newAdminFeeReceiver != address(0), "Invalid receiver address");
        if(adminFeeReceiver != _newAdminFeeReceiver) {
            adminFeeReceiver = _newAdminFeeReceiver;
            emit AdminFeeReceiverUpdated(adminFeeReceiver);
        }
    }

    
    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(
            _erc20s.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    
    function setERC721Permits(address[] memory _erc721s, bool[] memory _permits)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        require(
            _erc721s.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _erc721s.length; i++) {
            _setERC721Permit(_erc721s[i], _permits[i]);
        }
    }

    
    function getERC20Permit(address _erc20)
        public
        view
        override
        returns (bool)
    {
        return erc20Permits[_erc20];
    }

    
    function getERC721Permit(address _erc721)
        public
        view
        override
        returns (bool)
    {
        return erc721Permits[_erc721];
    }

    
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }

    
    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }

    
    function _setERC721Permit(address _erc721, bool _permit) internal {
        require(_erc721 != address(0), "erc721 is zero address");

        erc721Permits[_erc721] = _permit;

        emit ERC721Permit(_erc721, _permit);
    }
}