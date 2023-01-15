// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title StationXFactory Emitter Contract
/// @dev Contract Emits events for Factory and Proxy
contract Emitter is Initializable, AccessControl {
    //FACTORY EVENTS
    event ChangeImplementationAddress(
        address indexed factory,
        address indexed newImplementation
    );
    event ChangedUSDCAddress(address indexed factory, address indexed USDC);
    event CreateDao(
        address indexed ownerAddress,
        address indexed proxy,
        string name,
        string symbol,
        uint256 totalDeposit,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 ownerFee,
        uint256 _days,
        bool feeUSDC,
        uint256 quorum,
        uint256 threshold,
        address emitter,
        address[] daoAdmins,
        bool _isGovernanceActive
    );
    event FactoryCreated(
        address indexed _implementation,
        address indexed _USDC,
        address indexed _factory,
        address _emitter
    );

    //PROXY EVENTS
    event Deposited(
        address indexed _proxy,
        address indexed _depositor,
        address indexed _tokenAddress,
        uint256 _amount,
        uint256 _timeStamp,
        uint256 _ownerFee,
        uint256 _adminShare,
        bool _feeUSDC
    );
    event StartDeposit(
        address indexed _proxy,
        uint256 startTime,
        uint256 closeTime
    );
    event CloseDeposit(address indexed _proxy, uint256 closeTime);
    event UpdateMinMaxDeposit(
        address indexed _proxy,
        uint256 _minDeposit,
        uint256 _maxDeposit
    );
    event UpdateOwnerFee(address indexed _proxy, uint256 _ownerFee);
    event UpdateUSDCTokenAddress(
        address indexed _proxy,
        address indexed _USDCTokenAddress
    );
    event AirDropToken(
        address indexed _proxy,
        address _token,
        uint256 _amount,
        uint256 _ownersAirdropFees
    );
    event MintGTToAddress(
        address indexed _proxy,
        uint256[] _amount,
        address[] _userAddress
    );
    event UpdateGovernanceSettings(
        address indexed _proxy,
        uint256 _quorum,
        uint256 _threshold
    );
    event UpdateRaiseAmount(address indexed _proxy, uint256 _amount);
    event SendCustomToken(
        address indexed _proxy,
        address _token,
        uint256[] _amount,
        address[] _addresses
    );
    event SendEth(
        address indexed _proxy,
        uint256[] _amount,
        address[] _addresses
    );

    event DaoAdminsAdded(address indexed _proxy, address[] _daoAdmins);

    event NewUser(
        address indexed _proxy,
        address indexed _depositor,
        address indexed _tokenAddress,
        uint256 _usdcAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    );

    address private _factoryAddress;
    bytes32 public constant EMITTER = keccak256("EMITTER");

    function Initialize(
        address _implementation,
        address _USDC,
        address _factory
    ) public initializer {
        _factoryAddress = _factory;
        emit FactoryCreated(_implementation, _USDC, _factory, address(this));
    }

    /// @dev onlyOwner modifier to allow only Owner access to functions
    modifier onlyOwner() {
        require(_factoryAddress == msg.sender, "Only Owner");
        _;
    }

    function changeImplementationAddress(address _newImp) public onlyOwner {
        emit ChangeImplementationAddress(msg.sender, _newImp);
    }

    function changedUSDCAddress(address _newUSDC) public onlyOwner {
        emit ChangedUSDCAddress(msg.sender, _newUSDC);
    }

    function createDao(
        address _ownerAddress,
        address _proxy,
        string memory _name,
        string memory _symbol,
        uint256 _totalDeposit,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _ownerFee,
        uint256 _totalDays,
        bool _feeUSDC,
        uint256 _quorum,
        uint256 _threshold,
        address _emitter,
        address _usdc,
        address[] memory _daoAdmins,
        bool _isGovernanceActive
    ) public onlyOwner {
        _grantRole(EMITTER, _proxy);
        emit CreateDao(
            _ownerAddress,
            _proxy,
            _name,
            _symbol,
            _totalDeposit,
            _minDeposit,
            _maxDeposit,
            _ownerFee,
            _totalDays,
            _feeUSDC,
            _quorum,
            _threshold,
            _emitter,
            _daoAdmins,
            _isGovernanceActive
        );

        for (uint256 i = 0; i < _daoAdmins.length; i++) {
            emit NewUser(
                _proxy,
                _daoAdmins[i],
                _usdc,
                0,
                block.timestamp,
                0,
                true
            );
        }

        emit DaoAdminsAdded(_proxy, _daoAdmins);
    }

    function daoAdminsAdded(
        address _proxy,
        address[] memory _daoAdmins,
        address _usdc
    ) public onlyRole(EMITTER) {
        for (uint256 i = 0; i < _daoAdmins.length; i++) {
            emit NewUser(
                _proxy,
                _daoAdmins[i],
                _usdc,
                0,
                block.timestamp,
                0,
                true
            );
        }

        emit DaoAdminsAdded(_proxy, _daoAdmins);
    }

    function deposited(
        address _proxy,
        address _depositor,
        address _tokenAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _ownerFee,
        uint256 _adminShare,
        bool _feeUSDC
    ) public onlyRole(EMITTER) {
        emit Deposited(
            _proxy,
            _depositor,
            _tokenAddress,
            _amount,
            _timestamp,
            _ownerFee,
            _adminShare,
            _feeUSDC
        );
    }

    function newUser(
        address _proxy,
        address _depositor,
        address _tokenAddress,
        uint256 _usdcAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    ) public onlyRole(EMITTER) {
        emit NewUser(
            _proxy,
            _depositor,
            _tokenAddress,
            _usdcAmount,
            _timeStamp,
            _gtToken,
            _isAdmin
        );
    }

    function startDeposit(
        address _proxy,
        uint256 _startTime,
        uint256 _closeTime
    ) public onlyRole(EMITTER) {
        emit StartDeposit(_proxy, _startTime, _closeTime);
    }

    function closeDeposit(address _proxy, uint256 _closeTime)
        public
        onlyRole(EMITTER)
    {
        emit CloseDeposit(_proxy, _closeTime);
    }

    function updateMinMaxDeposit(
        address _proxy,
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) public onlyRole(EMITTER) {
        emit StartDeposit(_proxy, _minDeposit, _maxDeposit);
    }

    function updateOwnerFee(address _proxy, uint256 _ownerFee)
        public
        onlyRole(EMITTER)
    {
        emit UpdateOwnerFee(_proxy, _ownerFee);
    }

    function updateUSDCTokenAddress(address _proxy, address _USDCTokenAddress)
        public
        onlyRole(EMITTER)
    {
        emit UpdateUSDCTokenAddress(_proxy, _USDCTokenAddress);
    }

    function airDropToken(
        address _proxy,
        address _token,
        uint256 _amount,
        uint256 _ownersAirdropFees
    ) public onlyRole(EMITTER) {
        emit AirDropToken(_proxy, _token, _amount, _ownersAirdropFees);
    }

    function mintGTToAddress(
        address _proxy,
        uint256[] memory _amount,
        address[] memory _userAddress
    ) public onlyRole(EMITTER) {
        emit MintGTToAddress(_proxy, _amount, _userAddress);
    }

    function updateGovernanceSettings(
        address _proxy,
        uint256 _quorum,
        uint256 _threshold
    ) public onlyRole(EMITTER) {
        emit UpdateGovernanceSettings(_proxy, _quorum, _threshold);
    }

    function updateRaiseAmount(address _proxy, uint256 _amount)
        public
        onlyRole(EMITTER)
    {
        emit UpdateRaiseAmount(_proxy, _amount);
    }

    function sendCustomToken(
        address _proxy,
        address _token,
        uint256[] memory _amount,
        address[] memory _addresses
    ) public onlyRole(EMITTER) {
        emit SendCustomToken(_proxy, _token, _amount, _addresses);
    }

    function sendEth(
        address _proxy,
        uint256[] memory _amount,
        address[] memory _addresses
    ) public onlyRole(EMITTER) {
        emit SendEth(_proxy, _amount, _addresses);
    }
}