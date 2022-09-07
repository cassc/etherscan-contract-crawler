// SPDX-License-Identifier: GPL-3.0
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./utils/Context.sol";

pragma solidity 0.8.16;

/**
 * @title Partner Program's Contract
 * @author HeisenDev
 */
contract PartnerProgram is Context {
    using SafeMath for uint256;
    uint256 partnerProgramTax = 5;
    address private partnerProgramOwner;

    struct Project {
        address contractAddress;
        address payable paymentsWallet;
        uint256 partnerCommission;
        uint256 partnerPremiumCommission;
        address author;
        string coinName;
        string coinSymbol;
        string website;
        string twitter;
        string telegram;
        string discord;
        bool isValue;
    }

    struct Partner {
        string name;
        string code;
        address payable partnerAddress;
        address payable managerAddress;
        uint256 taxFeePartner;
        uint256 taxFeeManager;
        bool isValue;
    }

    mapping(string => Partner) public partners;
    mapping(address => Project) public projects;

    event Deposit(address sender, uint amount);
    event NewPartner(string name, string code);
    event UpdatePartner(string name, string code);
    event NewProject(address contractAddress, string _coinName, string _coinSymbol, string website);
    event UpdateProject(address contractAddress, string _coinName, string _coinSymbol, string website);

    event PartnerProgramBUY(address indexed sender, address indexed _contract, string indexed _code, uint amount);


    constructor(address _addr) {
        partnerProgramOwner = payable(_addr);
    }


    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(_msgSender(), msg.value);
        }
    }

    function executePaymentsETH(address _contractAddress, string memory _code) internal {
        uint256 amount = msg.value;
        Project storage _project = projects[_contractAddress];
        Partner storage _partner = partners[_code];
        uint partnerTaxesAmount = amount.mul(_project.partnerCommission).div(100);
        uint256 partnerAmount = partnerTaxesAmount.mul(_partner.taxFeePartner).div(100);
        uint256 managerAmount = partnerTaxesAmount.mul(_partner.taxFeeManager).div(100);
        uint256 partnerProgram = amount.mul(partnerProgramTax).div(100);
        amount = amount.sub(partnerAmount);
        amount = amount.sub(managerAmount);
        amount = amount.sub(partnerProgram);
        bool sent;
        (sent,) = _partner.partnerAddress.call{value : partnerAmount}("");
        require(sent, "Deposit ETH: failed to send ETH");
        (sent,) = _partner.managerAddress.call{value : managerAmount}("");
        require(sent, "Deposit ETH: Failed to send ETH");
        (sent,) = partnerProgramOwner.call{value : partnerProgram}("");
        require(sent, "Deposit ETH: Failed to send ETH");
        (sent,) = _project.paymentsWallet.call{value : amount}("");
        require(sent, "Deposit ETH: Failed to send ETH");
    }

    function executePaymentsTokens(address _contractAddress, string memory _code, uint256 _amount) internal {
        Partner storage _partner = partners[_code];
        uint256 partnerAmount = _amount.mul(_partner.taxFeePartner).div(100);
        uint256 managerAmount = _amount.sub(partnerAmount);
        IERC20 _token = IERC20(_contractAddress);
        _token.transfer(_partner.partnerAddress, partnerAmount);
        _token.transfer(_partner.managerAddress, managerAmount);
    }
    modifier isPartnerProgramContract(address _contractAddress) {
        require(projects[_contractAddress].isValue, "projects: project not exist");
        _;
    }

    modifier isPartnerProgramMember(string memory _code) {
        require(partners[_code].isValue, "Partners: code not exist");
        _;
    }

    function partnerProgramBUYTokens(uint _amount, string memory _code, address _contractAddress) external {
        require(partners[_code].isValue, "Partner Program BUY: code not exist");
        require(_amount > 0, "PartnerProgramBUY: You deposit send at least some tokens");
        IERC20 _token = IERC20(_contractAddress);
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "PartnerProgramBUY: Check the token allowance");
        _token.transferFrom(msg.sender, address(this), _amount);
        executePaymentsTokens(_contractAddress, _code, _amount);
        emit PartnerProgramBUY(_msgSender(), _contractAddress, _code, _amount);
    }

    function partnerProgramBUY(string memory _code, address _contractAddress) external payable isPartnerProgramMember(_code) isPartnerProgramContract(_contractAddress) {
        require(msg.value > 0, "You need to send some ether");
        executePaymentsETH(_contractAddress, _code);
        emit PartnerProgramBUY(_msgSender(), _contractAddress, _code, msg.value);
    }

    function joinAsProject(
        address _contractAddress,
        address payable _paymentsWallet,
        uint256 _partnerCommission,
        uint256 _partnerPremiumCommission,
        string memory _coinName,
        string memory _coinSymbol,
        string memory _website,
        string memory _twitter,
        string memory _telegram,
        string memory _discord) external {
        require(msg.sender == tx.origin, "New Project: contracts not allowed here");
        require(_partnerCommission > 0, "New Project: commission must be greater than zero");
        require(_partnerCommission <= 30, "New Project: partner commission must keep 30% or less");
        require(!projects[_contractAddress].isValue, "New Project: project already exists");
        IERC20 _token = IERC20(_contractAddress);
        require(_token.owner() == _msgSender(), "New Project: caller is not the owner");
        projects[_contractAddress] = Project({
        contractAddress : _contractAddress,
        paymentsWallet : _paymentsWallet,
        partnerCommission : _partnerCommission,
        partnerPremiumCommission : _partnerPremiumCommission,
        author : _msgSender(),
        coinName : _coinName,
        coinSymbol : _coinSymbol,
        website : _website,
        twitter : _twitter,
        telegram : _telegram,
        discord : _discord,
        isValue : true
        });
        emit NewProject(_contractAddress, _coinName, _coinSymbol, _website);
    }
    function updateProject (
        address _contractAddress,
        address payable _paymentsWallet,
        uint256 _partnerCommission,
        uint256 _partnerPremiumCommission,
        string memory _coinName,
        string memory _coinSymbol,
        string memory _website,
        string memory _twitter,
        string memory _telegram,
        string memory _discord) external {
        require(msg.sender == tx.origin, "Update Project: contracts not allowed here");
        require(msg.sender == tx.origin, "Update Project: projects not allowed here");
        require(_partnerCommission > 0, "Update Project: commission must be greater than zero");
        require(_partnerCommission <= 30, "Update Project: partner commission must keep 30% or less");
        IERC20 _token = IERC20(_contractAddress);
        require(_token.owner() == _msgSender(), "New Project: caller is not the owner");
        projects[_contractAddress] = Project({
        contractAddress : _contractAddress,
        paymentsWallet : _paymentsWallet,
        partnerCommission : _partnerCommission,
        partnerPremiumCommission : _partnerPremiumCommission,
        author : _msgSender(),
        coinName : _coinName,
        coinSymbol : _coinSymbol,
        website : _website,
        twitter : _twitter,
        telegram : _telegram,
        discord : _discord,
        isValue : true
        });
        emit UpdateProject(_contractAddress, _coinName, _coinSymbol, _website);
    }

    function joinAsPartner(
        string memory _name,
        string memory _code,
        address payable _partnerAddress,
        address payable _managerAddress,
        uint256 _taxFeePartner,
        uint256 _taxFeeManager) external {
        require(!partners[_code].isValue, "Partners: code already exists");
        require(_taxFeePartner + _taxFeeManager == 100, "The sum of the taxes must be 100");
        partners[_code] = Partner({
        name : _name,
        code : _code,
        partnerAddress : _partnerAddress,
        managerAddress : _managerAddress,
        taxFeePartner : _taxFeePartner,
        taxFeeManager : _taxFeeManager,
        isValue : true
        });
        emit NewPartner(_name, _code);
    }

    function updatePartner(
        string memory _name,
        string memory _code,
        address payable  _partnerAddress,
        address payable _managerAddress,
        uint256 _taxFeePartner,
        uint256 _taxFeeManager) external {
        Partner storage _partner = partners[_code];
        require(_partner.partnerAddress == _msgSender() , "Partners: only Partner can change the data");
        require(_taxFeePartner + _taxFeeManager == 100, "The sum of the taxes must be 100");
        partners[_code] = Partner({
        name : _name,
        code : _code,
        partnerAddress : _partnerAddress,
        managerAddress : _managerAddress,
        taxFeePartner : _taxFeePartner,
        taxFeeManager : _taxFeeManager,
        isValue : true
        });
        emit UpdatePartner(_name, _code);
    }
    function ownerPayment(address _contractAddress, uint256 _amount) external {
        IERC20 _token = IERC20(_contractAddress);
        _token.transfer(partnerProgramOwner, _amount);
        (bool sent,) = partnerProgramOwner.call{value : address(this).balance}("");
        require(sent, "recover ETH: Failed to send ETH");
    }
}