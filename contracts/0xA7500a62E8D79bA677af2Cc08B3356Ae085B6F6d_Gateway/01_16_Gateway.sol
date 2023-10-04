// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Escrow.sol";
import "./Dispute.sol";
import "./Agent.sol";
import "./interfaces/IGateway.sol";
import "./libraries/TransferHelper.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Gateway is Ownable, Escrow, Dispute, Agent, IGateway {
    // External token address, should be able to reset this by an owner
    address public token;

    mapping(uint256 => address[]) public reviewers;
    mapping(uint256 => address[]) public pickedAgents;

    constructor(address _token) {
        require(
            _token != address(0),
            "Invalid Token Address"
        );
        token = _token;
    }
    
    function resetTokenAddress(address _newTokenAddress) external onlyOwner {
        require(
            _newTokenAddress != address(0) && _newTokenAddress != address(this),
            "Invalid Token Address"
        );
        token = _newTokenAddress;
    }

    /* 
    * @param _escrowDisputableTime (Epoch time in seconds) - After this time, a customer can make a dispute case
    * @param _escrowWithdrawableTime (Epoch time in seconds) - After this time, a merchant can withdraw funds from an escrow contract
    */
    function purchase(
        uint256 _productId,
        address _merchantAddress,
        uint256 _amount,
        uint256 _escrowDisputableTime,
        uint256 _escrowWithdrawableTime
    ) public payable {
        _purchase(
            token,
            _msgSender(),
            _productId,
            _merchantAddress,
            _amount,
            _escrowDisputableTime,
            _escrowWithdrawableTime
        );
    }

    function withdraw(uint256 _escrowId) public {
        _withdraw(token, _msgSender(), _escrowId);
    }

    function startDispute(uint256 _escrowId) public {
        require(
            escrows[_escrowId].status == DEFAULT,
            "Escrow status must be on the DEFAULT status"
        );
        require(
            _msgSender() == escrows[_escrowId].buyerAddress,
            "Caller is not buyer"
        );
        require(
            escrows[_escrowId].escrowDisputableTime <= block.timestamp,
            "Please wait until the disputable time"
        );
        require(
            escrows[_escrowId].escrowWithdrawableTime >= block.timestamp,
            "Disputable time was passed already"
        );

        escrows[_escrowId].status = DISPUTE;
        _dispute(_msgSender(), _escrowId);
    }

    // Call this function to get credits as an Agent, should call approve function of Token contract before calling this function
    function participate() external {
        Agent memory agent = agents[_msgSender()];
        require(
            agent.status == 0 || // not exists
                agent.status == _LOST || // Agent submitted and lost
                    agent.status == _INIT, // Agent submitted and won
            "Wrong status"
        );
        require(
            TransferHelper.balanceOf(token, _msgSender()) >=
                agentPaticipateAmount,
            "Not correct amount"
        );

        if (agent.participationCount != 0 && agent.score < criteriaScore) {
            revert(
                "Your agent score is too low, so can't participate any more"
            );
        }

        if (agent.participationCount == 0) {
            agents[_msgSender()] = Agent(
                initialAgentScore,
                0,
                agentPaticipateAmount,
                0,
                _WAITING
            );
        } else {
            agents[_msgSender()] = Agent(
                agent.score,
                agent.participationCount,
                agent.accumulatedAmount + agentPaticipateAmount,
                0,
                _WAITING
            );
        }
        TransferHelper.safeTransferFrom(
            token,
            _msgSender(),
            address(this),
            agentPaticipateAmount
        );

        emit AgentParticipated(_msgSender());
    }

    function pickDispute(uint256 _disputeId)
        external
    {
        require(
            agents[_msgSender()].status == _WAITING,
            "Agent is not in waiting state"
        );
        require(
            agents[_msgSender()].score >= criteriaScore,
            "Low agent score"
        );
        require(disputes[_disputeId].escrowId != 0, "Invalid dispute id");
         require(disputes[_disputeId].applied_agents_count < disputeReviewGroupCount ||
            (disputes[_disputeId].createdAt + maxReviewDelay) < block.timestamp, "max applied agents exceed");
        require(
            disputes[_disputeId].status == INIT ||
                disputes[_disputeId].status == WAITING ||
                disputes[_disputeId].status == REVIEW,
            "Dispute is not in init nor in waiting status"
        );
        pickedAgents[_disputeId].push(_msgSender());
        disputes[_disputeId].status = REVIEW;
        agents[_msgSender()].status = REVIEW;
        agents[_msgSender()].assignedDisputeId = _disputeId;
        disputes[_disputeId].applied_agents_count +=1;
        emit AssignAgent(_msgSender(), _disputeId);
    }

    function _setAgent(
        Agent storage agent,
        uint256 status,
        uint256 score,
        uint256 assignedDisputeId
    ) internal {
        agent.status = status;
        if (status == _LOST) 
            agent.score -= score;
        else 
            agent.score += score;
        agent.assignedDisputeId = assignedDisputeId;
    }

    function _setDispute(
        Dispute storage dispute,
        uint256 status
    ) internal {
        dispute.status = status;
        if(status == FAIL){
            dispute.disapprovedCount += 1;
        }else if(status == WIN){
            dispute.approvedCount += 1;
        }else if( status == INIT){
            dispute.approvedCount = 0;
            dispute.disapprovedCount = 0;
        }
        dispute.updatedAt = block.timestamp;
    }

    // Need to have MTO transfered beforehand
    function submit(uint256 _disputeId, uint256 _decision) external {
        Dispute storage dispute = disputes[_disputeId];
        Agent storage agent;
        require(
            agents[_msgSender()].score >= criteriaScore,
            "Too low score as an Agent"
        );        
        require(
            agents[_msgSender()].status == _REVIEW,
            "Agent status should be review"
        );
        require(
            agents[_msgSender()].assignedDisputeId == _disputeId,
            "disputeID is not assigned"
        );
        require(
            disputes[agents[_msgSender()].assignedDisputeId].escrowId != 0,
            "DisputeID is not valid"
        );
        require(
            _decision == _APPROVED || _decision == _DISAPPROVED,
            "Invalid decision value"
        );

        agents[_msgSender()].participationCount += 1;
        if (
            _decision == _APPROVED &&
            dispute.approvedCount + 1 >= disputeReviewConsensusCount
        ) {
            _setAgent(agents[_msgSender()], _EARNED, scoreUp, 0);

            _setDispute(dispute, WIN);
            emit DisputeApproved(_disputeId);

            escrows[dispute.escrowId].status = REFUNDED; // REFUNDABLE; In case not returing the funds back to a customer in this function
            // Transfer the funds to a customer for chargeback as a dipsute case got approved
            TransferHelper.safeTransfer(
                token,
                escrows[dispute.escrowId].buyerAddress,
                escrows[dispute.escrowId].amount
            );
            emit Refunded(
                escrows[dispute.escrowId].buyerAddress,
                dispute.escrowId,
                escrows[dispute.escrowId].amount
            );

            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {
                agent = agents[reviewers[_disputeId][i]];
                if (agent.status == _APPROVED) {
                    _setAgent(agent, _EARNED, scoreUp, 0);
                } else if (agent.status == _DISAPPROVED) {
                    _setAgent(agent, _LOST, scoreDown, 0);
                }
            }
            for (uint256 i = 0; i < pickedAgents[_disputeId].length; i++) {
                agent = agents[pickedAgents[_disputeId][i]];
                _setAgent(agent, _WAITING, 0, 0);
            }

        } else if (
            _decision == _DISAPPROVED &&
            dispute.disapprovedCount + 1 >= disputeReviewConsensusCount
        ) {
            _setAgent(agents[_msgSender()], _EARNED, scoreUp, 0);
            _setDispute(dispute, FAIL);
            emit DisputeDisapproved(_disputeId);

            escrows[dispute.escrowId].status = COMPLETED; // DEFAULT; In case not returing the funds to a merchant in this function

            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {
                agent = agents[reviewers[_disputeId][i]];
                if (agent.status == _DISAPPROVED) {
                    _setAgent(agent, _EARNED, scoreUp, 0);
                } else if (agent.status == _APPROVED) {
                    _setAgent(agent, _LOST, scoreDown, 0);
                }
            }
            for (uint256 i = 0; i < pickedAgents[_disputeId].length; i++) {
                agent = agents[pickedAgents[_disputeId][i]];
                _setAgent(agent, _WAITING, 0, 0);
            }
            // Transfer the funds to a merchant for selling the product as a dipsute case(by a customer) got disapproved
            TransferHelper.safeTransfer(
                token,
                escrows[dispute.escrowId].merchantAddress,
                escrows[dispute.escrowId].amount
            );
            emit Withdraw(
                escrows[dispute.escrowId].merchantAddress,
                dispute.escrowId,
                escrows[dispute.escrowId].amount
            );
        } else if (
            _decision == _APPROVED &&
            dispute.approvedCount + 1 < disputeReviewConsensusCount &&
            (dispute.approvedCount + dispute.disapprovedCount + 1) >=
            disputeReviewGroupCount
        ) {
            _setAgent(agents[_msgSender()], _LOST, scoreDown, 0);
            _setDispute(dispute, INIT);

            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {
                _setAgent(
                    agents[reviewers[_disputeId][i]],
                    _LOST,
                    scoreDown,
                    0
                );
            }
            for (uint256 i = 0; i < pickedAgents[_disputeId].length; i++) {                
                _setAgent(agents[pickedAgents[_disputeId][i]], _WAITING, 0, 0);
            }
        } else if (
            _decision == _DISAPPROVED &&
            dispute.disapprovedCount + 1 < disputeReviewConsensusCount &&
            (dispute.approvedCount + dispute.disapprovedCount + 1) >=
            disputeReviewGroupCount
        ) {
            _setAgent(agents[_msgSender()], _LOST, scoreDown, 0);
            _setDispute(dispute, INIT);
            for (uint256 i = 0; i < reviewers[_disputeId].length; i++) {
                _setAgent(
                    agents[reviewers[_disputeId][i]],
                    _LOST,
                    scoreDown,
                    0
                );
            }
            for (uint256 i = 0; i < pickedAgents[_disputeId].length; i++) {                
                _setAgent(agents[pickedAgents[_disputeId][i]], _WAITING, 0, 0);
            }
        } else {            
            _setAgent(agents[_msgSender()], _decision, 0, 0);

            _removeFromPickedAgents(_disputeId, _msgSender());
            reviewers[_disputeId].push(_msgSender());

            dispute.status = WAITING;
            dispute.updatedAt = block.timestamp;

            if (_decision == _APPROVED) dispute.approvedCount += 1;
            else if (_decision == _DISAPPROVED) dispute.disapprovedCount += 1;
        }

        if (
            agents[_msgSender()].score < criteriaScore &&
            agents[_msgSender()].status != _BAN
        ) {
            agents[_msgSender()].status = _BAN;
        }

        emit SubmittedDispute(_msgSender(), _disputeId, _decision);
    }

    function agentWithdraw() external {
        require(
            agents[_msgSender()].status == _EARNED,
            "Cannot withdraw unearned tokens"
        );

        agents[_msgSender()].status = _INIT;
        TransferHelper.safeTransfer(token, _msgSender(), disputeBonusAmount);

        emit AgentWithdraw(_msgSender(), disputeBonusAmount);
    }

    function adminWithdrawToken(uint256 _amount) external onlyOwner {
        require(
            TransferHelper.balanceOf(token, address(this)) > _amount,
            "Not enough balance"
        );
        TransferHelper.safeTransfer(token, _msgSender(), _amount);
    }

    function getMerchantReputation(address _merchantAddress)
        public
        view
        returns (uint256)
    {
        require(_merchantAddress != address(0), "Invalid Merchant Address");

        if (currentEscrowId == 0) {
            return 0;
        }

        uint256 Es = 0; //total number of escrow for merchant address
        uint256 Ds = 0; //total win dispute againts merchant address
        uint256 Er = 0; //(escrow success ratio) = (Es - Ds)/Es

        uint256 Esa = 0; //total escrowed amount
        uint256 Dsa = 0; //total disputed amount
        uint256 Ar = 0; // (Amount ratio) = (Esa - Dsa) / Esa

        for (uint256 i = 1; i <= currentEscrowId; i++) {
            if (
                escrows[i].merchantAddress == _merchantAddress &&
                escrows[i].status != DISPUTE
            ) {
                if (
                    escrows[i].status != DEFAULT ||
                    escrows[i].escrowWithdrawableTime < block.timestamp
                ) {
                    Es = Es + 1;
                    Esa = Esa + escrows[i].amount;

                    if (
                        escrows[i].status == REFUNDABLE ||
                        escrows[i].status == REFUNDED
                    ) {
                        Ds = Ds + 1;
                        Dsa = Dsa + escrows[i].amount;
                    }
                }
            }
        }

        if (Es == 0) {
            return 0;
        }

        Er = ((60 * (Es - Ds)) / Es); //60 percent reputation for successful escrows
        Ar = ((40 * (Esa - Dsa)) / Esa); ////60 percent reputation for successful escrows Amount
        uint256 total = Er + Ar;
        return total;
    }

    function applyADM(uint256 _disputeId, uint256 _decision)
        external
        onlyOwner
    {
        Dispute storage dispute = disputes[_disputeId];
        Escrow storage escrow = escrows[dispute.escrowId];
        require(dispute.status == INIT, "Dispute is not in init state");
        require(
            _decision == _APPROVED || _decision == _DISAPPROVED,
            "Invalid decision value"
        );
        //APPROVE
        if (_decision == _APPROVED) {
            dispute.status = WIN;
            dispute.updatedAt = block.timestamp;
            emit DisputeApproved(_disputeId);

            escrow.status = REFUNDED;
            TransferHelper.safeTransfer(
                token,
                escrow.buyerAddress,
                escrow.amount
            );
            emit Refunded(escrow.buyerAddress, dispute.escrowId, escrow.amount);
        } else {
            //FAIL
            dispute.status = FAIL;
            dispute.updatedAt = block.timestamp;
            emit DisputeDisapproved(_disputeId);

            escrow.status = COMPLETED;

            TransferHelper.safeTransfer(
                token,
                escrow.merchantAddress,
                escrow.amount
            );

            emit Withdraw(
                escrow.merchantAddress,
                dispute.escrowId,
                escrow.amount
            );
        }
    }

    // TODO 1: fee, 2: reset global variables 3: auto assign system

    function _removeFromPickedAgents(uint256 disputeId, address agent) internal {
        address[] storage agents = pickedAgents[disputeId];
        uint i = _findIndex(agents, agent);
        _removeByIndex(agents, i);
    }

    function _removeByIndex(address[] storage agents, uint index) internal {
        if (index >= agents.length) return;

        agents[index] = agents[agents.length - 1];
        agents.pop();
    }

    function _findIndex(address[] storage agents, address submitter) internal view returns(uint) {
        uint i = 0;
        while (agents[i] != submitter) {
            i++;
        }
        return i;
    }
}