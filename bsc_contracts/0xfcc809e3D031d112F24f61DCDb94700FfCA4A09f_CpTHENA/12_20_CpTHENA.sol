// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./CpTHENASolidStaker.sol";
import "../interfaces/ISolidlyRouter.sol";

contract CpTHENA is CpTHENASolidStaker {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Needed addresses
    address[] public mainActiveVoteLps;
    address[] public reserveActiveVoteLps;
    ISolidlyRouter.Routes[] public wantToNativeRoute;

    // Events
    event ClaimVeEmissions(address indexed user, uint256 amount);
    event SetRouter(address oldRouter, address newRouter);
    event RewardsHarvested(uint256 rewardTHE, uint256 rewardCpTHENA);
    event Voted(uint256 tokenId, address[] votes, uint256[] weights);
    event ChargedFees(uint256 callFees, uint256 coFees, uint256 strategistFees);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxy,
        address[] calldata _manager,
        address _configurator,
        ISolidlyRouter.Routes[] calldata _wantToNativeRoute
    ) public initializer {
        CpTHENASolidStaker.init(
            _name,
            _symbol,
            _proxy,
            _manager[0],
            _manager[1],
            _manager[2],
            _manager[3],
            _configurator
        );

        for (uint i; i < _wantToNativeRoute.length; i++) {
            wantToNativeRoute.push(_wantToNativeRoute[i]);
        }
    }

    function voteInfo(uint256 _tokenId) external view
        returns (
            address[] memory lpsVoted,
            uint256[] memory votes,
            uint256 lastVoted
        ) {
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        
        uint256 len = mainActiveVoteLps.length;
        uint256 tokenId = mainTokenId;
        if (_tokenId == reserveTokenId) {
            tokenId = reserveTokenId;
            len = reserveActiveVoteLps.length;
        }

        lpsVoted = new address[](len);
        votes = new uint256[](len);
        for (uint i; i < len; i++) {
            lpsVoted[i] = solidVoter.poolVote(tokenId, i);
            votes[i] = solidVoter.votes(tokenId, lpsVoted[i]);
        }

        lastVoted = solidVoter.lastVoted(tokenId);
    }

    function claimVeEmissions() public {
        uint256 _amount = proxy.claimVeEmissions();
        uint256 gap = totalWant() - totalSupply();
        if (gap > 0) {
            uint256 feePercent = configurator.getFee();
            address coFeeRecipient = configurator.coFeeRecipient();
            uint256 feeBal = (gap * feePercent) / MAX_RATE;
            
            if (feeBal > 0) _mint(address(coFeeRecipient), feeBal);
            _mint(address(daoWallet), gap - feeBal);
        }

        emit ClaimVeEmissions(msg.sender, _amount);
    }

    function vote(
        uint256 _tokenId,
        address[] calldata _tokenVote,
        uint256[] calldata _weights,
        bool _withHarvest
    ) external onlyVoter {
        // Check to make sure we set up our rewards
        for (uint i; i < _tokenVote.length; i++) {
            require(proxy.lpInitialized(_tokenVote[i]), "Staker: TOKEN_VOTE_INVALID");
        }

        uint256 reserveTokenId = proxy.reserveTokenId();
        bool isReserve = _tokenId == reserveTokenId;
        if (_withHarvest) {
            harvestVe(isReserve);
        }
        
        if (isReserve) {
            reserveActiveVoteLps = _tokenVote;
        } else {
            mainActiveVoteLps = _tokenVote;
        }

        // We claim first to maximize our voting power.
        claimVeEmissions();
        proxy.vote(_tokenId, _tokenVote, _weights);
        emit Voted(_tokenId, _tokenVote, _weights);
    }

    /**
     * @param _type (bool): true - harvestVeReserve, false - harvestVeMain.
    */
    function harvestVe(bool _type) public {
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        
        uint256 tokenId = mainTokenId;
        address[] memory activeVoteLps = mainActiveVoteLps;
        if(_type) {
            tokenId = reserveTokenId;
            activeVoteLps = reserveActiveVoteLps;
        }

        for (uint i; i < activeVoteLps.length; i++) {
            proxy.getBribeReward(tokenId, activeVoteLps[i]);
            proxy.getTradingFeeReward(tokenId, activeVoteLps[i]);
        }

        _chargeFees();
    }

    function _chargeFees() internal {
        uint256 rewardTHEBal = IERC20Upgradeable(want).balanceOf(address(this));
        uint256 rewardCpTHENABal = balanceOf(address(this));
        uint256 feePercent = configurator.getFee();
        address coFeeRecipient = configurator.coFeeRecipient();

        if (rewardTHEBal > 0) {
            uint256 feeBal = (rewardTHEBal * feePercent) / MAX_RATE;
            if (feeBal > 0) {
                IERC20Upgradeable(want).safeApprove(address(router), feeBal);
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    feeBal,
                    0,
                    wantToNativeRoute,
                    address(coFeeRecipient),
                    block.timestamp
                );
                IERC20Upgradeable(want).safeApprove(address(router), 0);
                emit ChargedFees(0, feeBal, 0);
            }

            IERC20Upgradeable(want).safeTransfer(daoWallet, rewardTHEBal - feeBal);
        }

        if (rewardCpTHENABal > 0) {
            uint256 feeBal = (rewardCpTHENABal * feePercent) / MAX_RATE;
            if (feeBal > 0) {
                IERC20Upgradeable(address(this)).safeTransfer(address(coFeeRecipient), feeBal);
                emit ChargedFees(0, feeBal, 0);
            }

            IERC20Upgradeable(address(this)).safeTransfer(daoWallet, rewardCpTHENABal - feeBal);
        }

        emit RewardsHarvested(rewardTHEBal, rewardCpTHENABal);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        address sender = _msgSender();
        uint256 taxAmount = _chargeTaxTransfer(sender, to, amount);
        _transfer(sender, to, amount - taxAmount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 taxAmount = _chargeTaxTransfer(from, to, amount);
        _transfer(from, to, amount - taxAmount);
        return true;
    }

    function _chargeTaxTransfer(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 taxSellingPercent = configurator.hasSellingTax(from, to);
        uint256 taxBuyingPercent = configurator.hasBuyingTax(from, to);
        uint256 taxPercent = taxSellingPercent > taxBuyingPercent ? taxSellingPercent: taxBuyingPercent;
		if(taxPercent > 0) {
            uint256 taxAmount = amount * taxPercent / MAX;
            uint256 amountToDead = taxAmount / 2;
            _transfer(from, configurator.deadWallet(), amountToDead);
            _transfer(from, polWallet, taxAmount - amountToDead);
            return taxAmount;
		}

        return 0;
    }

    // Set our router to exchange our rewards, also update new thenaToNative route.
    function setRouterAndRoute(address _router, ISolidlyRouter.Routes[] calldata _route) external onlyManager {
        emit SetRouter(address(router), _router);
        delete wantToNativeRoute;
        for (uint i; i < _route.length; i++) wantToNativeRoute.push(_route[i]);
        router = ISolidlyRouter(_router);
    }
}