// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./libs/NFTreasuryLib.sol";
import "./interfaces/INFTicketProcessor.sol";
import "./interfaces/INFTicket.sol";
import "./interfaces/INFTServiceTypes.sol";

contract NFTicket is Initializable, OwnableUpgradeable, ERC721URIStorageUpgradeable, INFTicket {
    using NFTreasuryLib for NFTreasuryLib.Treasury;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint;

    mapping(address => bool) _whitelist;


    modifier QualifiedServiceProviderOnly(address serviceProviderContract, uint32 sD) { // TODO confirm serviceProvider serves that serviceDescriptor
        isServiceProviderFor(serviceProviderContract, sD);
        _;
    }

    modifier onlyWhiteList(address sender) {
        require(inWhitelist(sender), "not white");
        _;
    }
    function removeWhitelist(address _address) public {
        _whitelist[_address] = false;
    }
    function addWhitelist(address _address) external {
        _whitelist[_address] = true;
    }


    function inWhitelist(address _address)
        public
        view
        returns (bool)
    {
        return bool(_whitelist[_address]);
    }

    address ticketProcessor;
    // NFTicketLib.TicketLib ticketLib;
    NFTreasuryLib.Treasury treasuryLib;
    CountersUpgradeable.Counter private _tokenIds;

/*******
*
* replace constructor with initialize() for upgradeable contract
    constructor(
        address _erc20,
        uint32 transactionFee,
        uint32 ratioBase
    ) ERC721("NFTicket", "BLXFT") {
        ERC20_Token = _erc20;
        treasuryLib.TRANSACTIONFEE = transactionFee;
        treasuryLib.ratioBASE = ratioBase;
        treasuryLib.ERC20_Token = _erc20;
        treasuryLib.owner = owner();
        treasuryLib.nfticket = address(this);
    }
********/
    function initialize(
        address _erc20,
        uint32 transactionFee,
        uint32 ratioBase
    ) initializer public {
        __Ownable_init();
        __ERC721_init("NFTicket", "BLXFT");
        treasuryLib.TRANSACTIONFEE = transactionFee;
        treasuryLib.ratioBASE = ratioBase;
        treasuryLib.ERC20_Token = _erc20;
        treasuryLib.owner = owner();
        treasuryLib.nfticket = address(this);
    }
    /******************
    *
    * The ticketProcessor is allowed to transfer tickets under custody of NFTicket
    *
    *******************/
    function initProcessor(address _processor) 
        public 
        onlyOwner
    {
        ticketProcessor = _processor;
        setApprovalForAll(ticketProcessor, true);
    }

    function getTicketProcessor()
        public
        override
        view
        onlyWhiteList(msg.sender)
        returns (address)
    {
        return(ticketProcessor);
    }

    function getMasterWallet()
        public
        view
        onlyWhiteList(msg.sender)
        returns (address)
    {
        return treasuryLib.owner;
    }

    function setMasterWallet(address master) external onlyOwner {
        treasuryLib.owner = master;
    }

    function mintNFTicket(
        address recipient,
        Ticket memory ticket
    )
        external
        payable
        override
        returns (Ticket memory _ret)
    {
        // TODO require() that reseller is either a registered reseller or serviceProvider;
        uint256 serviceFee;
        uint256 resellerFee;
        uint256 transactionFee;
        _ret = ticket;
        _ret.tokenID = _tokenIds.current();

        _mint(recipient, _ret.tokenID);
        _setTokenURI(_ret.tokenID, _ret.tokenURI);
        treasuryLib.setTicketData(_ret.tokenID, _ret);
        (serviceFee, resellerFee, transactionFee) = treasuryLib.splitRevenue(_ret, _ret.price);
        emit SplitRevenue(
            _ret.tokenID,
            msg.value,
            serviceFee,
            resellerFee,
            transactionFee
        );
        _tokenIds.increment();

        return (_ret);
    }

    function getTicketData(uint256 ticketID)
        public
        override
        view
        returns (Ticket memory _t)
    {
        // TODO hb220710 verify calling party is whitelisted for this ticket
        _t = treasuryLib.ticketData[ticketID];
        return (_t);
    }

    function updateTicketData(uint256 ticketID, Ticket memory _t)
        public
    {
        treasuryLib.ticketData[ticketID] = _t;
    }

    function presentTicketFeeToPool(Ticket memory _t, uint256 credits, address ERC20Token) 
        public
        returns (Ticket memory ticket)
    {
        ticket = treasuryLib.presentTicketFeeToPool(_t, credits, ERC20Token);
        return(ticket);
    }

    function withDrawCredits(uint256 ticketID, address erc20Contract, uint256 credits, address sendTo) 
        external
        override
    {
        Ticket memory _t = treasuryLib.getTicketData(ticketID);
        require(credits <= _t.credits, "insufficient credits");

        emit WithDrawCredits(ticketID, erc20Contract, credits, msg.sender, sendTo);
    }

    function withDrawERC20(uint256 ticketID, address erc20Contract, uint256 amountERC20Tokens, address sendTo) 
        external
        override
    {  

        treasuryLib.withDrawERC20(ticketID, erc20Contract, amountERC20Tokens);

        TransferHelper.safeTransfer(erc20Contract, sendTo, amountERC20Tokens);

        emit WithDrawERC20(ticketID, erc20Contract, amountERC20Tokens, msg.sender, sendTo);
    }

    /*********************************
    *
    * lockTicket and releaseTickets in this form are both called by the ServiceProvider smart contract
    * TODO: need B2C equivalent functions where ms.sender is the user
    *
    function lockTicket(uint256 ticketID, address presenter, address serviceProviderContract, uint256 reduceCreditsBy)
        external
        override
        QualifiedServiceProviderOnly(msg.sender, treasuryLib.getTicketData(ticketID).serviceDescriptor)
    {
        INFTicketProcessor(ticketProcessor).lockTicket(ticketID, presenter, serviceProviderContract, reduceCreditsBy);
    }

    function releaseTicket(uint256 ticketID, address ticketReceiver, address serviceProviderContract, uint256 reduceCreditsBy)
        external 
        override
        QualifiedServiceProviderOnly(msg.sender, treasuryLib.getTicketData(ticketID).serviceDescriptor)
    {
        INFTicketProcessor(ticketProcessor).releaseTicket(ticketID, ticketReceiver, serviceProviderContract, reduceCreditsBy);
    }
    *********************************/

    function topUpTicket(uint256 ticketID, uint256 creditsAdded, address erc20Contract, uint256 numberERC20Tokens)
        external
        override
        returns(uint256 creditsAffordable, uint256 chargedERC20)
    {
        uint32 status;
        (status, creditsAffordable, chargedERC20) = treasuryLib.topUpTicket(ticketID, creditsAdded, erc20Contract, numberERC20Tokens);
         
        Ticket memory _t = treasuryLib.getTicketData(ticketID);
        TransferHelper.safeTransferFrom(
            erc20Contract,
            msg.sender,
            address(this),
            numberERC20Tokens
        );

        emit IncomingFunding(
            ticketID,
            erc20Contract,
            msg.sender,
            address(this),
            _t.credits,
            _t.price,
            _t.serviceDescriptor
        );

        emit TopUpTicket( // JAN
            ticketID, 
            creditsAdded, 
            erc20Contract, 
            numberERC20Tokens, 
            creditsAffordable, 
            chargedERC20
        );

        return(creditsAffordable, chargedERC20);
        
    }

    function updateServiceType(uint256 ticketID, uint32 serviceDescriptor)
        QualifiedServiceProviderOnly(msg.sender, serviceDescriptor)
        public
        override
        returns(uint256 _sD)
    {
        Ticket memory ticket = getTicketData(ticketID);
        _sD = treasuryLib.updateServiceType(ticket, serviceDescriptor);
        return(_sD);

    }
    function presentCertificateRepurchase(address sender, Ticket memory _t)
        public
    {
        treasuryLib.presentCertificateRepurchase(sender, _t);
    }
    function getResellerPoolSize(address serviceProvider)
        external
        view
        returns (
            /* , address reseller TODO provider:reseller m:n instead of 1:1 */
            uint256 poolSize
        )
    {
        return (treasuryLib.getResellerPoolSize(serviceProvider));
    }

    function getTransactionPoolSize() 
        external 
        override
        view 
        returns (uint256) 
    {
        return (treasuryLib.getTransactionPoolSize());
    }

    function getServiceProviderPoolSize(address serviceProvider)
        external
        override
        view
        returns (uint256 poolSize)
    {
        return (treasuryLib.getServiceProviderPoolSize(serviceProvider));
    }

    function getTotalTicketPoolSize() 
        external
        override 
        view 
        returns (uint256) 
    {
        return (treasuryLib.getTotalTicketPoolSize());
    }

    function getTicketBalance(uint256 tokenID) 
        external
        override 
        view 
        returns (uint256) 
    {
        return (treasuryLib.getTicketBalance(tokenID));
    }

    /*
    function consumeCredits(
        address serviceProvider,
        uint256 _tokenID,
        uint256 _consumeCredits
    )
        external
        override
        returns (uint256 creditsConsumed, uint256 creditsRemain)
    {
        require(
            treasuryLib.ticketData[_tokenID].credits - _consumeCredits >= 0,
            "not enough credits left on Ticket"
        );

        uint256 _serviceProvider = uint256(uint160(serviceProvider));
        require(
            msg.sender ==
                treasuryLib.serviceProvidersReseller.get(
                    uint256(_serviceProvider)
                ),
            "require a valid reseller"
        );

        creditsConsumed = INFTServiceProvider(serviceProvider).consumeCredits(
            treasuryLib.ticketData[_tokenID],
            _consumeCredits
        );

        creditsRemain = treasuryLib.consumeCredits(_tokenID, creditsConsumed);
        emit ConsumedCredits(_tokenID, creditsConsumed, creditsRemain);
        return (creditsConsumed, creditsRemain);
    }
    */

    function registerResellerServiceProvider(
        address serviceProvider,
        address reseller,
        address resellerWallet
    ) external override onlyWhiteList(msg.sender) returns (uint16 status) {
        status = 201;
        require(
            treasuryLib.isRegisteredServiceProvider(serviceProvider),
            "SP not regd"
        );
        status = treasuryLib.registerServiceReseller(
            serviceProvider,
            reseller,
            resellerWallet
        );
    }

    function registerServiceProvider(
        address serviceProvider,
        uint32 serviceDescriptor,
        address serviceProviderWallet
    ) external override onlyWhiteList(msg.sender) returns (uint16 status) {
        status = 201;
        status = treasuryLib.registerServiceProvider(
            serviceProvider,
            serviceDescriptor,
            serviceProviderWallet
        );
        emit RegisterServiceProvider(
            serviceProvider,
            serviceDescriptor,
            status
        );
    }

    function getTreasuryOwner()
        public
        override
        view
        returns(address owner)
    {
        return(treasuryLib.owner);
    }

    function getCompanyDescriptor(address serviceProvider)
        external
        view
        returns (uint32 descriptor)
    {
        descriptor = treasuryLib.getCompanyDescriptor(serviceProvider);
    }

    function getReseller(address serviceProvider)
        external
        view
        returns (address contractAddress, address walletAddress)
    {
        contractAddress = treasuryLib.serviceProvidersReseller[serviceProvider];
        walletAddress = treasuryLib.serviceProviderAccount[serviceProvider].resellerWallet;
    }

    function isServiceProviderFor(address serviceContract, uint32 /* serviceDescriptor */)
        public
        view
        returns (bool _isServiceProviderFor) 
    {
        _isServiceProviderFor = false;

        if (isServiceProvider(serviceContract)) {
            // if providesService(serviceContract, serviceDescriptor) TODO - really need to figure out data model and data flow for Ticket and Service
            _isServiceProviderFor = true;
        } else {
            _isServiceProviderFor = false;
        }

        return(_isServiceProviderFor);
    }

    function isServiceProvider(address sContract) public view returns (bool) {
        return (treasuryLib.getCompanyDescriptor(sContract) != 0);
    }

    function getServiceProvider(uint32 companyDescriptor)
        public
        view
        returns (address contractAddress, address walletAddress)
    {
        contractAddress = treasuryLib._providers[companyDescriptor];
        require(contractAddress != address(0), "undef SP");
        walletAddress = treasuryLib
            .serviceProviderAccount[contractAddress]
            .serviceProviderWallet;
    }
  

}