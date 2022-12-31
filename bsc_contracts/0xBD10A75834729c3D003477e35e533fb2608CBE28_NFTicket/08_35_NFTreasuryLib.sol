// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./TransferHelper.sol";
import "../interfaces/INFTServiceTypes.sol";
import "../interfaces/INFTicket.sol";

library NFTreasuryLib {
    using SafeMath for uint;

    event ExceptionFeesInsufficientValue(
        uint256 value,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256 transactionFee
    );

    struct RevenuePool {
        address resellerWallet; // reseller's wallet
        address serviceProviderWallet; // service provider's wallet
        uint256 serviceTicketPool; // total unclaimed serviceFees
        uint256 resellerPool; // acc revenue pool for reseller
        uint256 serviceProviderPool; // acc revenue pool for service provider
    }

    enum erc20 {BLXM, USDC, EWT, CELO, cUSD}

    // TODO prepare for multi-token logic
    struct poolsByToken {
        string tokenTicker;
        address contractAddress;
        mapping(address => uint256) contractBalance; // total liquid balance
        mapping(address => uint256) transactionPool;
        mapping(address => RevenuePool) serviceProviderAccount;
        mapping(uint256 => uint256) remainingTicketBalance;
    }

    struct Treasury {
        // these values are initiated in NFTicket constructor{}
        address owner;
        address nfticket;
        address ERC20_Token;
        uint32 TRANSACTIONFEE; // promil, i.e. 1.5%
        uint32 ratioBASE;
        uint256 _totalTicketPool;


        
        // main accounts by role in NFTicket
        mapping(address => uint256) _contractBalance; // total liquid balance
        mapping(address => uint256) transactionPool;
        mapping(address => RevenuePool) serviceProviderAccount;
        mapping(uint256 => uint256) remainingTicketBalance; // mapping of ticketID to balance

        /*
         * TODO
         * only have 1:1 mapping between reseller and provider for now.
         * Need to extends this to m:n or at least
         * 1:n 1 reseller having several service provider
         */
        mapping(address => address) resellersServiceProvider;
        mapping(address => address) serviceProvidersReseller;
        mapping(uint32 => address) _providers;
        mapping(address => uint32) _companyDescriptors;
        mapping(uint256 => Ticket) ticketData;
    }


    function init(
        Treasury storage _treasury,
        address _nfticket
    )
        public
    {
        _treasury.nfticket = _nfticket;
        // TODO multi-token struct poolsByToken[uint256(erc20.BLXM)].contractBalance = _treasury._contractBalance;

    }
    function consumeCredits(
        Treasury storage _treasury,
        uint256 tokenID,
        uint256 creditsConsumed
    ) public returns (uint256 remainingCredits) {
        _treasury.ticketData[tokenID].credits -= creditsConsumed;
        remainingCredits = _treasury.ticketData[tokenID].credits;
    }

    function getResellerWallet(
        Treasury storage _treasury,
        address serviceProviderContract
    ) 
        public 
        view
        returns (address _wallet) 
    {
        return (
            _treasury.serviceProviderAccount[serviceProviderContract].resellerWallet
        );
    }

    function getTicketData(Treasury storage _treasury, uint256 tokenID)
        public
        view
        returns(Ticket memory ticket)
    {
        ticket = _treasury.ticketData[tokenID];
        return(ticket);
    }
    function getServiceProviderWallet(
        Treasury storage _treasury,
        address serviceProviderContract
    ) 
        public 
        view
        returns (address _wallet) 
    {
        return (
            _treasury
                .serviceProviderAccount[serviceProviderContract]
                .serviceProviderWallet
        );
    }

    function getResellerPoolSize(
        Treasury storage _treasury,
        address serviceProvider
    ) internal view returns (uint256 poolSize) {
        return (_treasury.serviceProviderAccount[serviceProvider].resellerPool);
    }

    function getTransactionPoolSize(Treasury storage _treasury)
        internal
        view
        returns (uint256 poolSize)
    {
        return (_treasury.transactionPool[_treasury.owner]);
    }

    function getServiceProviderPoolSize(
        Treasury storage _treasury,
        address serviceProvider
    ) internal view returns (uint256 poolSize) {
        return (
            _treasury.serviceProviderAccount[serviceProvider].serviceProviderPool
        );
    }

    function setTicketData(
        Treasury storage _treasury,
        uint256 newTicketID,
        Ticket memory ticket
    ) internal {
        _treasury.ticketData[newTicketID] = ticket;
    }

    function getTotalTicketPoolSize(Treasury storage _treasury)
        internal
        view
        returns (uint256 poolSize)
    {
        return (_treasury._totalTicketPool);
    }

    function getTicketBalanceByERC20(Treasury storage _treasury, uint256 tokenID, address)
        internal
        view
        returns (uint256)
    {
        return (_treasury.remainingTicketBalance[tokenID]);
    }

    function getTicketBalance(Treasury storage _treasury, uint256 tokenID)
        internal
        view
        returns (uint256)
    {
        return (_treasury.remainingTicketBalance[tokenID]);
    }

    /*********
    *
    * validate ticket types.
    *
    ***********/
    function isCertificate(Treasury storage, Ticket memory ticket) 
        public
        pure
        returns(bool _isCertificate)
    {

        _isCertificate = ((ticket.serviceDescriptor & IS_CERTIFICATE) == IS_CERTIFICATE);
        return(_isCertificate);
    }
    function isTicket(Treasury storage, Ticket memory ticket) 
        public
        pure
        returns(bool _isTicket)
    {

        _isTicket = ((ticket.serviceDescriptor & IS_TICKET) == IS_TICKET); 
        return(_isTicket);
    }
    function isCashVoucher(Treasury storage, Ticket memory ticket) 
        public
        pure
        returns(bool _isCashVoucher)
    {
        _isCashVoucher = ((ticket.serviceDescriptor & CASH_VOUCHER) == CASH_VOUCHER);
    }
    // end of ticket type validation
    
    function updateServiceType(Treasury storage _treasury, Ticket memory ticket, uint32 serviceDescriptor)
        public
        returns(uint32) 
    {
        uint32 currentSD = ticket.serviceDescriptor;
        uint32 currentCompany =  currentSD % 0x400; // current company descriptor
        uint32 newCompany = serviceDescriptor % 0x400;
        if (currentCompany != newCompany) {
            string memory _msg = "Company=";
            _msg = string(abi.encodePacked(_msg, Strings.toString(newCompany), " not allowed to change services for company=", Strings.toString(newCompany)));
            require(currentCompany == newCompany, _msg);
        }
        ticket.serviceDescriptor = serviceDescriptor;
        setTicketData(_treasury, ticket.tokenID, ticket);

        return(serviceDescriptor ^ newCompany); //  XOR of equal values should return 0
    }
    
    function withDrawERC20(Treasury storage _treasury, uint256 ticketID, address, uint256 amountERC20Tokens)
        public
        returns(Ticket memory)
    {
    
        uint256 currentBalance = getTicketBalance(_treasury, ticketID);
        uint256 currentTicketPool = _treasury._totalTicketPool;

        Ticket memory ticket = getTicketData(_treasury, ticketID);
        require(amountERC20Tokens <= currentBalance, "insufficient ERC20 tokens on NFTicket");
        reduceTicketBalance(_treasury, ticket, amountERC20Tokens);

        uint256 newBalance = getTicketBalance(_treasury, ticketID);
        uint256 newTicketPool = _treasury._totalTicketPool;
        require(currentBalance.sub(amountERC20Tokens) == newBalance, "ticket balance not correctly reduced");
        require(currentTicketPool.sub(amountERC20Tokens) == newTicketPool, "ticket pool not correctly reduced");

        if ( isCashVoucher(_treasury, ticket )) {
            return(ticket);
        } else {
            uint256 reducedBalance = getTicketBalance(_treasury, ticketID);
            uint256 reduceCreditsBy = reducedBalance.div(ticket.pricePerCredit);
            if(reduceCreditsBy >= ticket.credits) {
                ticket.credits = 0;
            } 
            else {
                ticket.credits = ticket.credits.sub(reduceCreditsBy);
            }
        }
        
        setTicketData(_treasury, ticketID, ticket);
        return(ticket);
    }

    function addTicketBalance(Treasury storage _treasury, Ticket memory ticket, uint256 increaseBalanceBy) 
        internal
    {
        _treasury.remainingTicketBalance[ticket.tokenID] += increaseBalanceBy;
        _treasury._totalTicketPool += increaseBalanceBy;
    }

    function reduceTicketBalance(Treasury storage _treasury, Ticket memory ticket, uint256 reduceBalanceBy) 
        internal
    {
        _treasury.remainingTicketBalance[ticket.tokenID] -= reduceBalanceBy;
        _treasury._totalTicketPool -= reduceBalanceBy;
    }

     function _splitRevenue(Treasury storage _treasury, Ticket memory ticket, uint256 serviceFee, uint256 resellerFee, uint256 transactionFee) 
        public
        {
            // Treasury keeps TX fees
        _treasury.transactionPool[_treasury.owner] += transactionFee;

        if (isCashVoucher(_treasury, ticket)) {
            require( (ticket.pricePerCredit == 0) &&  (ticket.credits == 0), "CASH_VOUCHER MUST have ppC == credits == 0");
            distributeTicketRevenueToPool(_treasury, ticket, serviceFee, resellerFee, transactionFee);
        } else if (isCertificate(_treasury, ticket)) {
            distributeCertificateRevenueToPool(_treasury, ticket, serviceFee, resellerFee, transactionFee);
        } else if (isTicket(_treasury, ticket)) {
            distributeTicketRevenueToPool(_treasury, ticket, serviceFee, resellerFee, transactionFee);
        } else {
            string memory _msg;

            _msg = "service Descriptor ";
            _msg = string(
                abi.encodePacked(
                    _msg,
                    Strings.toHexString(ticket.serviceDescriptor),
                    " neither CERT nor TICKET nor CASH_VOUCHER"
                )
            );
            require ( (isCertificate(_treasury, ticket) || isTicket(_treasury, ticket) || isCashVoucher(_treasury, ticket)), _msg );
        }

        setTicketData(_treasury, ticket.tokenID, ticket);
    }

    /*****************************************
     *
     * TODO: this should be called once to determine the main values
     * calculate values and pass the actual splitting of revenue to _splitRevenue
     * strong case to be made to use ERC155 here, because all tokens with the same ID can share same formula
     * but we are free to create different token classes identified by their tokenIDs
     *
     ******************************************/
    function splitRevenue(
        Treasury storage _treasury,
        Ticket memory ticket,
        uint256 totalIncome
        ) internal returns (uint256, uint256 , uint256 ) {
        uint256 resellerFee = ticket.resellerFee; // e.g. 100 on a base of 1.000 -> 0.1 = 10%
        uint256 f = ticket.resellerFee.add(ticket.serviceFee); 
        f = f.add(ticket.transactionFee); // full share --> BASE
        uint256 v = uint256(_treasury.ratioBASE).mul(1 ether);
        string memory _msg;
        if ( f !=  v ) {
            _msg = "resellerFee= ";
            _msg = string(abi.encodePacked(_msg,Strings.toString(ticket.resellerFee)," + serviceFee=", 
                Strings.toString(ticket.serviceFee),
                " != txBASE=",(Strings.toString(_treasury.ratioBASE * (1 ether)))));
            require(f == v, _msg);
        }
        // total transaction fee = _treasury.TRANSACTIONFEE * (f = resellerFee + serviceFee)
        uint256 transactionShare = ticket.price.mul(_treasury.TRANSACTIONFEE); // e.g. 3.000 = 300 * 10 on a BASE of 1.000
        transactionShare = transactionShare.div(_treasury.ratioBASE); // 3 <= price=300 * TXfee=10 / BASE=1000
        ticket.transactionFee = uint256(_treasury.TRANSACTIONFEE).mul(1 ether);
       
        /****
        *
        * ALL EXAMPLES GIVEN: price = 300; txFEE = 10 ; txBASE = 1.000
        *  Calculate absolute (serviceShare) and relative (serviceFee) by subtracting relative txFee
        *  where:
            price * serviceFee = serviceShare 
        *
        *****/

        uint256 serviceShare = ticket.serviceFee.mul(ticket.price); // e.g. 270.000 = 900 * 300 
        serviceShare = serviceShare.div(1 ether).div(_treasury.ratioBASE); // e.g. 270 = price * ticket.serviceFee / txBASE, i.e. share before txFee
        uint256 transactionCost = serviceShare.mul(_treasury.TRANSACTIONFEE); // 
        transactionCost = transactionCost.div(_treasury.ratioBASE); // e.g. 2.7 = 270 * 10/1000
        serviceShare -= transactionCost; // e.g. 267.3 = 270 - 2.7; i.e. NET serviceShare AFTER txFEE
        uint256 serviceFee = ticket.serviceFee.mul(_treasury.TRANSACTIONFEE); // e.g. 9.000
        ticket.serviceFee -= serviceFee.div(_treasury.ratioBASE); // e.g 891 = 900 - 9{=9.000/txBASE=1.000}; so, e.g price=300 * 891/1.000=txFEE => serviceShare=267.3

        /****
        *
        *  Calculate absolute (resellerShare) and relative (resellerFee) reseller's share
        *  where:
            price * resellerFee = resellerShare
        *
        *****/
        uint256 resellerShare = ticket.resellerFee.mul(ticket.price); // e.g. 30.000 = 100 * 300
        resellerShare = resellerShare.div(1 ether).div(_treasury.ratioBASE); // e.g 30 = price * ticket.resellerFee / txBASE, i.e. share before txFEE
        transactionCost = resellerShare.mul(_treasury.TRANSACTIONFEE); // e.g. 30 * 10 = 300
        transactionCost = transactionCost.div(_treasury.ratioBASE); // e.g. 0.3 = 300 / 1.000 
        resellerShare -= transactionCost; // e.g. 29.7 = 30 - 0.3; i.e. NET serviceShare AFTER txFEE
        resellerFee = ticket.resellerFee.mul(_treasury.TRANSACTIONFEE); // e.g. 1.000
        ticket.resellerFee -= resellerFee.div(_treasury.ratioBASE); // e.g. 99 = 100 - 1{=1.000/txBASE=1.000}; so, e.g price=300 * 99/1.000=txFEE => resellerShare=29.7

        /********* START Treasury magicK ***********
         *
         * update pools and allowances
         * bracket by verifying distribution BEFORE and AFTER
         *
         ********************************************/
        verifyAllowances(_treasury, ticket, totalIncome, serviceShare, resellerShare, transactionShare);
        _splitRevenue(_treasury, ticket, serviceShare, resellerShare, transactionShare);
        if ( ! isCashVoucher(_treasury, ticket)) {
            require(ticket.credits != 0, "credits zero in splitRevenue && ! isCashVoucher()");
            ticket.pricePerCredit = ticket.price.div(serviceFee);
        } else {
            require(((ticket.credits == 0) && (ticket.pricePerCredit == 0)), "isCashVoucher BUT: credits OR ppC != 0 ");
        }
        verifyAllowances(_treasury, ticket, totalIncome, serviceShare, resellerShare, transactionShare);
        /********* END of Treasury magicK ***********/
        
        return (serviceShare, resellerShare, transactionShare);
    }

    function fundCashVoucher(Treasury storage _treasury, Ticket memory ticket, address, uint256 erc20Tokens)
        public
        returns(uint256 addedTokens)
    {
        uint256 resellerFee = 0;
        uint256 transactionFee = 0;


        if ( ! isCashVoucher(_treasury, ticket) ) {
            string memory _msg;

            _msg = "SP_DESCRIPTOR ";
            _msg = string(abi.encodePacked(_msg, Strings.toString(ticket.serviceDescriptor), " is not a CASH_VOUCHER "));
            require(false, _msg); // if condition has established isCashVoucher() == false
        }
        require(((ticket.credits == 0) && (ticket.pricePerCredit == 0)) , "require credits == pricePerCredit == 0 for CASH_VOUCHER");

        uint256 ticketBalanceBefore = _treasury.remainingTicketBalance[ticket.tokenID];

        _splitRevenue(_treasury, ticket, erc20Tokens, resellerFee, transactionFee);
        uint256 ticketBalanceAfter = _treasury.remainingTicketBalance[ticket.tokenID];
        require(ticketBalanceAfter.sub(ticketBalanceBefore) == erc20Tokens);

        return(erc20Tokens);
    }


    function topUpTicket(Treasury storage _treasury, uint256 ticketID, uint256 credits, address erc20Contract, uint256 erc20Tokens) 
        public
        returns(uint32 status, uint256 creditsAffordable, uint256 chargedERC20)
    {
         status = 200;
         // update ticket fees
         uint256 ticketBalanceBefore = _treasury.remainingTicketBalance[ticketID];
         Ticket memory ticket = _treasury.ticketData[ticketID];
         uint256 resellerFee;
         uint256 transactionFee;
         string memory _msg;

         
         // IF THIS TRUE THEN go to fundTicket and RETURN FROM HERE
         if ( isCashVoucher(_treasury, ticket)) {
            require(credits == 0, 'CASH_VOUCHER cannot be loaded with credit points');
            uint256 addedTokens = fundCashVoucher(_treasury, ticket, erc20Contract, erc20Tokens); // credits == 0; ppC == 0
            return(201, 0, addedTokens);
         }
         
         _msg = 'Ticket has ppC == 0; SP_DESCRIPTOR = ';
         _msg = string(abi.encodePacked(_msg, Strings.toString(ticket.serviceDescriptor)));
         require(! (ticket.pricePerCredit == 0), _msg);
         // CASH_VOUCHER RETURNs BEFORE THIS
         
         require(credits != 0, 'cannot top up 0 credits');
         creditsAffordable = erc20Tokens.div(ticket.pricePerCredit);

         // SP_DESCRIPTOR != CASH_VOUCHER
         if (creditsAffordable >= credits ) {
            if( creditsAffordable > credits ) {
                creditsAffordable = credits;
            }
            // TODO charge credits and return possible Overpay
            require( ticket.pricePerCredit != 0, "ppC needs to be != 0");
            chargedERC20 = creditsAffordable.mul(ticket.pricePerCredit);

            ticket.credits += creditsAffordable;
            resellerFee = 0;
            transactionFee = 0;
         } else {
            _msg = "insufficient credits=";
            _msg = string(abi.encodePacked(_msg,Strings.toString(credits), " can afford only=",Strings.toString(creditsAffordable), " ppC=", Strings.toString(ticket.pricePerCredit)));
            require(false, _msg);
            status = 400;
         }

        _splitRevenue(_treasury, ticket, chargedERC20, resellerFee, transactionFee);
        uint256 ticketBalanceAfter = _treasury.remainingTicketBalance[ticketID];
        if ( ticketBalanceAfter.sub(ticketBalanceBefore) != chargedERC20 ) {
            _msg = "ticketBalanceAfter=";
            _msg = string(abi.encodePacked(_msg,Strings.toString(ticketBalanceAfter), " - ticketBalanceBefore=", Strings.toString(ticketBalanceBefore), " != chargedERC20=", Strings.toString(chargedERC20)));
            require(ticketBalanceAfter.sub(ticketBalanceBefore) == chargedERC20, _msg);
        }
        /*****
        *
        * pricePerCredit is a derived value. It represents net balance divided by number of credits
        * We need to do it this way to always be able to charge exactly and safely by credits without risk of overrun.
        *
        *******/
        ticket.pricePerCredit = ticketBalanceAfter.div(ticket.credits);
        verifyAllowances(_treasury, ticket, chargedERC20, chargedERC20, resellerFee, transactionFee);
        uint256 ticketBalance = _treasury.remainingTicketBalance[ticket.tokenID];
        if (ticket.pricePerCredit.mul(uint256(ticket.credits)) != ticketBalance) {
            _msg = "ppC=";
            _msg = string(abi.encodePacked(_msg, Strings.toString(ticket.pricePerCredit), " != ticketBalance=", Strings.toString(ticketBalance.div(ticket.credits))));
            require(ticket.pricePerCredit == ticketBalance.div(ticket.credits), _msg);
        }

        return(status, creditsAffordable, chargedERC20);

    }

   

    function updateTicketPools(
        Treasury storage _treasury,
        address serviceProvider,
        Ticket memory ticket,
        uint256 serviceFee,
        uint256 resellerFee
    ) public {
        bool scenarioExists = false;
        if ( isCertificate(_treasury, ticket) && (! isCashVoucher(_treasury, ticket))) { // not sure whether there is a scenario where isCertificate && isCashVoucher both true 
        /*****
        *
        * certificates are proof of ownership
        * proof of ownership is immediately transferred vs. becoming credits to drawn down in tickets
        * this means the service provider is immediately credited with his share of the ticket price
        *
        ********/
        scenarioExists = true;
        addTicketBalance(_treasury, ticket, serviceFee);
        address resellerWallet = getResellerWallet(_treasury, serviceProvider);
        address serviceProviderWallet = getServiceProviderWallet(_treasury, serviceProvider);
        // serviceProvider share
        _treasury.serviceProviderAccount[serviceProvider].serviceProviderPool 
            += serviceFee;
        TransferHelper.safeApprove(_treasury.ERC20_Token, serviceProviderWallet,
            _treasury.serviceProviderAccount[serviceProvider].serviceProviderPool);

        // reseller share
        _treasury.serviceProviderAccount[serviceProvider].resellerPool += resellerFee;
        TransferHelper.safeApprove(_treasury.ERC20_Token, resellerWallet, 
            _treasury.serviceProviderAccount[ticket.serviceProvider].resellerPool);

        } else if (isTicket(_treasury, ticket) || isCashVoucher(_treasury, ticket) ) {
            scenarioExists = true;
            addTicketBalance(_treasury, ticket, serviceFee);
            _treasury.serviceProviderAccount[serviceProvider].serviceTicketPool += serviceFee;
            _treasury.serviceProviderAccount[serviceProvider].resellerPool += resellerFee;
            
            TransferHelper.safeApprove(_treasury.ERC20_Token, _treasury.owner, 
                _treasury.transactionPool[_treasury.owner] +
                _treasury.serviceProviderAccount[serviceProvider].serviceTicketPool
            );
        // reseller fee for reseller
        address resellerWallet = getResellerWallet(_treasury, serviceProvider);
        string memory _msg = "resellerWallet for SP=";
        _msg = string(abi.encodePacked(_msg, Strings.toString(uint160(serviceProvider))," is ", Strings.toString(uint160(resellerWallet))));
        require(resellerWallet != address(0), _msg);
        TransferHelper.safeApprove(_treasury.ERC20_Token, resellerWallet, 
            _treasury.serviceProviderAccount[serviceProvider].resellerPool);
        }

        require(scenarioExists, 'updateTPools: unknown scenario');
    }

    function distributeTicketRevenueToPool(
        Treasury storage _treasury,
        Ticket memory ticket,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256
    ) public {
        updateTicketPools(_treasury, ticket.serviceProvider, ticket, serviceFee, resellerFee);
        // minting fee for NFTicket MSC
        
    }

    function distributeCertificateRevenueToPool(
        Treasury storage _treasury,
        Ticket memory ticket,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256
    ) 
        public 
    {
        updateTicketPools(_treasury, ticket.serviceProvider, ticket, serviceFee, resellerFee);
    }

    function presentTicketFeeToPool(Treasury storage _treasury, Ticket memory ticket, 
        uint256 credits, address ERC20Token) 
        internal 
        returns(Ticket memory)
    {
        string memory _msg;
        address serviceProviderWallet = getServiceProviderWallet(_treasury, ticket.serviceProvider);

        uint256 originalServiceProviderPool = getServiceProviderPoolSize(_treasury, ticket.serviceProvider);
        uint256 originalServiceProviderAllowance = IERC20(ERC20Token).allowance(address(this), serviceProviderWallet);
        if (originalServiceProviderPool != originalServiceProviderAllowance) {
            _msg = "Service Provider pool and allowance differ ";
            _msg = string(abi.encodePacked(_msg,Strings.toString(originalServiceProviderPool)," ", Strings.toString(originalServiceProviderAllowance)));
            require(originalServiceProviderPool == originalServiceProviderAllowance, _msg);
        }

        require(ticket.credits != 0, "cannot credit ticket with remaining credit of 0");
        uint256 valueCredited = ( _treasury.remainingTicketBalance[ticket.tokenID] * credits) / ticket.credits;
        require(_treasury.remainingTicketBalance[ticket.tokenID] >= valueCredited, "tokenBalance insufficient");
        require(_treasury.serviceProviderAccount[ticket.serviceProvider].serviceTicketPool >= valueCredited, 
            "serviceTicketPool insufficient");
      
        // Commit TX
        _treasury.remainingTicketBalance[ticket.tokenID] -= valueCredited;
        _treasury.serviceProviderAccount[ticket.serviceProvider].serviceTicketPool -= valueCredited;
        _treasury._totalTicketPool -= valueCredited;


        _treasury.serviceProviderAccount[ticket.serviceProvider].serviceProviderPool += valueCredited;
        ticket.credits -= credits;
        _treasury.ticketData[ticket.tokenID] = ticket;
        TransferHelper.safeApprove(ERC20Token,serviceProviderWallet, 
            _treasury.serviceProviderAccount[ticket.serviceProvider].serviceProviderPool);
        TransferHelper.safeApprove(ERC20Token, _treasury.owner, 
            _treasury.transactionPool[_treasury.owner] +
            _treasury.serviceProviderAccount[ticket.serviceProvider].serviceTicketPool);

        return(ticket);
    }

    function presentCertificateRepurchase(Treasury storage _treasury, address sender,Ticket memory ticket) 
        internal 
        returns(Ticket memory)
    {
        uint256 refundValue = ticket.certValue;
        address serviceProviderContract = ticket.serviceProvider;
        address serviceProviderWallet = getServiceProviderWallet(_treasury, ticket.serviceProvider);
        uint256 availableFunds = getServiceProviderPoolSize(_treasury, ticket.serviceProvider);
        uint256 availableAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), serviceProviderWallet);
        uint256 serviceProviderWalletFunds = IERC20(_treasury.ERC20_Token).balanceOf(serviceProviderWallet);

        /**** START Verification */
        string memory _msg = "ServiceProvider contract ";
        string memory id = Strings.toString(
            uint256(uint160(serviceProviderContract))
        );
        if ( ! ((availableFunds + serviceProviderWalletFunds) >= refundValue) ) {
            _msg = string(abi.encodePacked(_msg, id, " and wallet "));
            id = Strings.toString(uint256(uint160(serviceProviderWallet)));
            _msg = string(
                abi.encodePacked(_msg, id, " have insufficient availableFunds=")
            );
            id = Strings.toString(availableFunds);
            _msg = string(abi.encodePacked(_msg, id, "/availableAllowance="));
            id = Strings.toString(availableAllowance);
            _msg = string(abi.encodePacked(_msg, id, "  plus insufficient availableWalletBalance= "));
            id = Strings.toString(serviceProviderWalletFunds);
            _msg = string(abi.encodePacked(_msg, id, " to refund certificate valued at "));
            id = Strings.toString(ticket.certValue);
            _msg = string(abi.encodePacked(_msg, id, " .1"));
            require( (availableFunds + serviceProviderWalletFunds) >= refundValue, _msg);
        }
        /**** END Verification  */

        /**********
         *
         * if allowance for service provider covers the cost of refunding
         * we transfer from our treasury and reduce the allowance of the serviceProvider
         *
         **********/
        if (refundValue <= availableFunds) {
            _treasury.serviceProviderAccount[ticket.serviceProvider].serviceProviderPool -= refundValue;
            TransferHelper.safeTransferFrom(_treasury.ERC20_Token,_treasury.owner,sender,refundValue);
            // reduce allowance for Service Provider
        } else if (refundValue <= (availableFunds + serviceProviderWalletFunds) ) {
            uint256 gap = refundValue - availableFunds;
            // first empty local balance
            _treasury.serviceProviderAccount[ticket.serviceProvider].serviceProviderPool -= availableFunds;
            TransferHelper.safeTransferFrom(_treasury.ERC20_Token, _treasury.owner, sender, availableFunds);
            // then use remote wallet allowance
            TransferHelper.safeTransferFrom(_treasury.ERC20_Token, serviceProviderWallet, sender, gap);

            // TODO emit Event
        }
        ticket.credits = 0;
        setTicketData(_treasury, ticket.tokenID, ticket);
        TransferHelper.safeApprove(_treasury.ERC20_Token, serviceProviderWallet,
            _treasury.serviceProviderAccount[ticket.serviceProvider].serviceProviderPool);

        return(ticket);
    }

 
    function verifyAllowances(Treasury storage _treasury, Ticket memory ticket, uint256 totalAmount, uint256 serviceFee, uint256 resellerFee, uint256 transactionFee) 
        internal  
        view
    {
        uint256 nfticketAllowance;
        uint256 resellerAllowance;
        uint256 serviceProviderAllowance;
        uint256 contractBalance;

        // TODO this is only for one SP and one Reseller
        // so need to identify SP:reseller pair with a unique identifier and
        // keep separate accounts for each such pair

        contractBalance = IERC20(_treasury.ERC20_Token).balanceOf(_treasury.owner);
        address resellerWallet = getResellerWallet(_treasury, ticket.serviceProvider);
        address serviceProviderWallet = getServiceProviderWallet(_treasury, ticket.serviceProvider);
        
        nfticketAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), _treasury.owner);
        resellerAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), resellerWallet);
        serviceProviderAllowance = IERC20(_treasury.ERC20_Token).allowance(address(this), serviceProviderWallet);

    
        
        /*
        string memory _msg;
        if ( !( nfticketAllowance + resellerAllowance + serviceProviderAllowance <= contractBalance )) {
            _msg = "Contract balance ";
            _msg = string(abi.encodePacked(_msg, abi.encodePacked(Strings.toString(contractBalance)),
                    " is insufficient for (nfticketAllowance = "));
            _msg = string(abi.encodePacked(_msg, abi.encodePacked(Strings.toString(nfticketAllowance)),
                    ") + (resellerAllowance = "));
            _msg = string(abi.encodePacked(_msg, abi.encodePacked(Strings.toString(resellerAllowance)),
                    ")"));
        */
            require(nfticketAllowance + resellerAllowance + serviceProviderAllowance <= contractBalance,"VerifyAllowances: balance insufficient");
        /* } */
        // sum of absolute fees are equal to full ticket price
        require((serviceFee + resellerFee + transactionFee) == totalAmount, "Absolute fees do not add up.");
        // sum of relative fees are equal to ratioBase
        /*
        if ((ticket.serviceFee + ticket.resellerFee + ticket.transactionFee).div(1 ether) != _treasury.ratioBASE) {
            _msg = "Relative fees do not add up. serviceFee = ";
            uint256 v = (ticket.serviceFee + ticket.resellerFee + ticket.transactionFee).div(1 ether);
            _msg = string(abi.encodePacked(_msg, "fees =",Strings.toString(v), " ratioBASE=",Strings.toString(_treasury.ratioBASE)));
        */
            require( ((ticket.serviceFee + ticket.resellerFee + ticket.transactionFee).div(1 ether)) == _treasury.ratioBASE,"VerifyAllowances: fees dont add up");
        /* } */

    }

    function isRegisteredServiceProvider(
        Treasury storage _treasury,
        address serviceProvider
    ) public view returns (bool) {
        return (_treasury._companyDescriptors[serviceProvider] != 0);
    }

    function registerServiceProvider(
        Treasury storage _treasury,
        address serviceProvider,
        uint32 companyDescriptor,
        address serviceProviderWallet
    ) internal returns (uint16 status) {
        if (isRegisteredServiceProvider(_treasury, serviceProvider)) {
            // this provider is already registered
            // TODO CRUD?
            require(false, "serviceProvider is already registered");
        } else {
            // register self as counterparty both as reseller as well as serviceProvider
            // this means this is a serviceProvider without a reseller
            _treasury._providers[companyDescriptor] = serviceProvider;
            _treasury._companyDescriptors[serviceProvider] = companyDescriptor;
            _treasury.serviceProvidersReseller[serviceProvider] = serviceProvider;
            _treasury.resellersServiceProvider[serviceProvider] = serviceProvider;
            _treasury.serviceProviderAccount[serviceProvider].serviceProviderWallet = serviceProviderWallet;
            _treasury.serviceProviderAccount[serviceProvider].resellerWallet = serviceProviderWallet;
        }
        return (200);
    }

    function getCompanyDescriptor(
        Treasury storage _treasury,
        address serviceProvider
    ) public view returns (uint32 descriptor) {
        return _treasury._companyDescriptors[serviceProvider];
    }

    function registerServiceReseller(
        Treasury storage _treasury,
        address serviceProvider,
        address reseller,
        address _resellerWallet
    ) internal returns (uint16 status) {

        _treasury.serviceProvidersReseller[serviceProvider] = reseller;
        _treasury.resellersServiceProvider[reseller] =  serviceProvider;
        _treasury.serviceProviderAccount[serviceProvider].resellerWallet = _resellerWallet;
        _treasury.serviceProviderAccount[serviceProvider].resellerPool = 0;

        return (200);
    }

    function storeCash(
        Treasury storage _treasury,
        address payable _owner,
        uint256 value
    ) public {
        _treasury.transactionPool[_owner] += value;
    }
}