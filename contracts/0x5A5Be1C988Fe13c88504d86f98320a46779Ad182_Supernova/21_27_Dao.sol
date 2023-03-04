// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./libs/Pausable.sol";
import "./Supernova.sol";

contract Dao is Initializable, Pausable {
    Supernova _SupernovaBridge;
    uint256 CLASSIC_DEF;
    uint256 DOUBLE_DEF;
    uint256 CLASSIC_MIN;
    uint256 DOUBLE_MIN;
    uint256 CLASSIC_MAX;
    uint256 DOUBLE_MAX;
    uint256 FULLCYCLE_MAX;
    uint256 MINIMUM;
    uint256 VOTELIMIT;
    uint256 public _FULLCYCLE;
    uint64 QUEUE_CURRENT;
    uint64 QUEUE_INPROCESS;
    address private UNISWAP_V2_ROUTER;
    address private WETH;
    bytes32 _Hash;
    address private _M87;
    address private _supernova;
    uint256[] public executing_Ids;
    uint256[] public queue_Ids;

    address ORACLE;
    // Create a struct named Proposal containing all relevant information
    struct Proposal {
        // address of the token being used for a purchase, can be zero address in case of ETH
        address sellToken;
        //  address of the token being purchased, can be zero address in case of ETH
        address buyToken;
        // general params
        string proposalTitle;
        string proposalDescription;
        address creator;
        ProposalType proposalType;
        // state enum dedicates operations @dev see: enum
        State activeState;
        // signers[0] is creator powehi, others are signer powehi
        address[] signers;
        uint256 date;
        uint256 amount;
        // number of YES votes for this proposal
        uint256 yesVotes;
        // number of NO votes for this proposal
        uint256 noVotes;
        // voters - halo's voted on proposal
        mapping(address => bool) voters;
    }

    enum Vote {
        YES,
        NO
    }

    enum ProposalType {
        CLASSIC,
        DOUBLE_DOWN,
        CASH_OUT,
        STRUCTURE
    }

    enum State {
        CREATED, // submitted/created by powehi, waiting other powehi to sign
        QUEUED, // signed by required number of powehi, waiting for amount to collect
        VOTING,
        RUNNING, // voting opened and waiting for dao decision
        EXECUTED, // voting succeed and swap executed
        FAILED // voting failed
    }

    // events

    event ProposalCreated(
        address creator,
        uint256 proposalIndex,
        address sellToken,
        address buyToken,
        string title,
        string description
    );
    event ProposalStatus(
        address creator,
        uint256 proposalIndex,
        address sellToken,
        address buyToken,
        State st
    );
    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public _stroreSigner;
    // index of array same as enum ProposalType
    uint8[] public signersRequired;

    // Number of proposals that have been created
    uint256 public numProposals;

    modifier OnlyOracle() {
        require(msg.sender == ORACLE, "Not a ORACLE");
        _;
    }

    function ff() public view returns (address, address) {
        return (msg.sender, ORACLE);
    }

    modifier notSigner(uint256 _proposalIndex) {
        require(
            _stroreSigner[msg.sender][_proposalIndex] == false,
            "Caller already signed this proposal"
        );
        _;
    }

    modifier atState(uint256 _proposalIndex, State _state) {
        require(
            proposals[_proposalIndex].activeState == _state,
            "Wrong state. Action not allowed."
        );
        _;
    }
    modifier stateQuorum(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].signers.length >=
                signersRequired[uint8(proposals[_proposalIndex].proposalType)],
            "Wrong state. Action not allowed."
        );
        _;
    }

    modifier _IsHalo(address _index) {
        require(_SupernovaBridge.Halo_finder(_index), "Not a Halo");
        _;
    }
    modifier _IsPowehi(address _index) {
        require(_SupernovaBridge.Powehi_finder(_index), "Not a Powehi");
        _;
    }

    modifier Bridge(bytes32 hsh) {
        require(_Hash == hsh);
        _;
    }

    function setup(
        address _oracle,
        address _m87,
        bytes32 _has,
        uint8[] memory signers
    ) public initializer {
        // signersRequired[0] = 8;
        // signersRequired[1] = 7;
        // signersRequired[2] = 3;
        // signersRequired[3] = 11;
        signersRequired = signers;
        ORACLE = _oracle;
        _M87 = _m87;
        _Hash = _has;

        CLASSIC_DEF = 8700000000000000000; //wei 8.7
        DOUBLE_DEF = 17400000000000000000; //wei 17.4
        CLASSIC_MIN = 870000000000000000; //wei 0.87
        DOUBLE_MIN = 8700000000000000000; //wei 8.7
        CLASSIC_MAX = 87000000000000000000; //wei 8.7
        DOUBLE_MAX = 26100000000000000000; //wei 26.1
        FULLCYCLE_MAX = 87000000000000000000; //wei 87  ETH
        UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        MINIMUM = 87 * 1e8 * 1e18;
        VOTELIMIT = 87 * 60 * 60; //87 Hours
        _FULLCYCLE = 87;
        QUEUE_CURRENT = 0;
        QUEUE_INPROCESS = 0;
        numProposals = 0;

        __Ownable_init();
    }

    function _Set_SupernovaBridgeBridge(address _fb)
        external
        onlyOwner
        returns (bool)
    {
        _supernova = _fb;
        _SupernovaBridge = Supernova(payable(_fb));
        return true;
    }

    function getBridge() public view returns (address) {
        return _supernova;
    }

    function getsignersRequired(uint256 inex) public view returns (uint8) {
        return signersRequired[inex];
    }

    /// @dev createProposal allows a Powehi to create a new proposal in the DAO
    /// @return Returns the proposal index for the newly created proposal
    function createCashOutProposal(
        address _sellToken,
        string memory _proposalTitle,
        string memory _proposalDescription,
        uint256 persentage
    ) external _IsPowehi(msg.sender) returns (uint256) {
        require(persentage <= 5000, "Buy and sell token can't be same");
        //50%
        (bool b, uint256 i) = _SupernovaBridge.isSupportedToken(_sellToken);
        require(b, "Buy token is not supported");

        Proposal storage proposal = proposals[numProposals];
        proposal.sellToken = _sellToken;
        proposal.buyToken = address(0xdead);
        proposal.proposalTitle = _proposalTitle;
        proposal.proposalDescription = _proposalDescription;
        proposal.signers = [msg.sender];
        proposal.activeState = State.CREATED;
        proposal.proposalType = ProposalType.CASH_OUT;
        proposal.date = VOTELIMIT + block.timestamp;
        proposal.amount = persentage;
        _stroreSigner[msg.sender][numProposals] = true;
        numProposals++;

        emit ProposalCreated(
            msg.sender,
            numProposals - 1,
            _sellToken,
            address(0xdead),
            _proposalTitle,
            _proposalDescription
        );

        return numProposals - 1;
    }

    function createDoubleClassicProposal(
        address _buyToken,
        string memory _proposalTitle,
        string memory _proposalDescription,
        uint256 amount,
        bool double
    ) external _IsPowehi(msg.sender) returns (uint256) {
        if (double) {
            if (amount >= DOUBLE_MIN && amount <= DOUBLE_MAX) {
                Proposal storage proposal = proposals[numProposals];
                proposal.sellToken = address(0xdead);
                proposal.buyToken = _buyToken;
                proposal.proposalTitle = _proposalTitle;
                proposal.proposalDescription = _proposalDescription;
                proposal.signers = [msg.sender];
                proposal.activeState = State.CREATED;
                proposal.date = block.timestamp;
                proposal.amount = amount;
                proposal.proposalType = ProposalType.DOUBLE_DOWN;
            } else {
                revert("MIN AND MAX LIMITION");
            }
        } else {
            if (amount >= CLASSIC_MIN && amount <= CLASSIC_MAX) {
                Proposal storage proposal = proposals[numProposals];
                proposal.sellToken = address(0xdead);
                proposal.buyToken = _buyToken;
                proposal.proposalTitle = _proposalTitle;
                proposal.proposalDescription = _proposalDescription;
                proposal.signers = [msg.sender];
                proposal.activeState = State.CREATED;
                proposal.date = block.timestamp;
                proposal.amount = amount;
                proposal.proposalType = ProposalType.CLASSIC;
            } else {
                revert("MIN AND MAX LIMITION CLASSIC");
            }
        }

        _stroreSigner[msg.sender][numProposals] = true;
        numProposals++;

        emit ProposalCreated(
            msg.sender,
            numProposals - 1,
            address(0xdead),
            _buyToken,
            _proposalTitle,
            _proposalDescription
        );

        return numProposals - 1;
    }

    function createStructureProposal(
        string memory _proposalTitle,
        string memory _proposalDescription
    ) external _IsPowehi(msg.sender) returns (uint256) {
        Proposal storage proposal = proposals[numProposals];
        proposal.sellToken = address(0xdead);
        proposal.buyToken = address(0xdead);
        proposal.proposalTitle = _proposalTitle;
        proposal.proposalDescription = _proposalDescription;
        proposal.signers = [msg.sender];
        proposal.activeState = State.CREATED;
        proposal.proposalType = ProposalType.STRUCTURE;
        proposal.date = block.timestamp;
        proposal.amount = 0;

        _stroreSigner[msg.sender][numProposals] = true;
        numProposals++;
        emit ProposalCreated(
            msg.sender,
            numProposals - 1,
            address(0xdead),
            address(0xdead),
            _proposalTitle,
            _proposalDescription
        );

        return numProposals - 1;
    }

    function signOnProposal(uint256 proposalIndex)
        external
        _IsPowehi(msg.sender)
        notSigner(proposalIndex)
        atState(proposalIndex, State.CREATED)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint8 signersNum = uint8(proposal.signers.length);

        proposal.signers.push(msg.sender);
        _stroreSigner[msg.sender][signersNum] = true;
    }

    function getCurrentStatus() public view returns (uint256 _c, uint256 _f) {
        return (numProposals, _FULLCYCLE);
    }

    
    function CheckOutsign(uint proposalsIndex) public view returns (uint _exsit, uint _require,uint _date) {
         Proposal storage proposal = proposals[proposalsIndex];
       
        return (proposal.signers.length, signersRequired[uint8(proposal.proposalType)],  proposal.date);
    }
    function VoteOnProposal(uint256 proposalIndex, uint8 vote)
        external
        _IsHalo(msg.sender)
    stateQuorum(proposalIndex)
    atState(proposalIndex, State.VOTING)
    {
        if (vote != 0 && vote != 1) {
            revert("You should send  0 or 1");
        }
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.voters[msg.sender]) {
            revert("You have already voted");
        }
        if (block.timestamp > proposal.date) {
            revert("You have already voted");
        }

        // uint8 signersNum = uint8(proposal.signers.length);

        if (vote == 0) {
            //yes
            proposal.yesVotes += 1;
        } else {
            //no
            proposal.noVotes += 1;
        }
        proposal.voters[msg.sender] = true;
    }

    function CloseProposal(uint256 _idQ)
        public
        atState(_idQ, State.VOTING)
        OnlyOracle
        returns (bool)
    {
        Proposal storage proposal = proposals[_idQ];
        proposal.activeState = State.FAILED;
        return true;
    }

    function ProposalCheckOut(uint256 _idQ, uint256[] memory x)
        private
        OnlyOracle
        returns (bool)
    {
        Proposal storage proposal = proposals[_idQ];
        //
        if(proposal.activeState ==State.QUEUED){

        uint256 _Index = getId(_idQ);
        if (proposal.proposalType == ProposalType.CLASSIC) {
            if (queue_Ids[_Index] == _idQ) {
                queue_Ids[_Index] = queue_Ids[_Index];
                queue_Ids.pop();

                sendToExecution(_idQ, x);
            } else {
                revert("You should chose First one");
            }
        } else if (proposal.proposalType == ProposalType.DOUBLE_DOWN) {
            if (queue_Ids[_Index] == _idQ) {
                queue_Ids[_Index] = queue_Ids[_Index];
                queue_Ids.pop();

                sendToExecution(_idQ, x);
            } else {
                revert("You should chose First one");
            }
        } else if (proposal.proposalType == ProposalType.CASH_OUT) {
            sendToExecution(_idQ, x);
        } else if (proposal.proposalType == ProposalType.STRUCTURE) {
            if (queue_Ids[_Index] == _idQ) {
                queue_Ids[_Index] = queue_Ids[_Index];
                queue_Ids.pop();

                sendToExecution(_idQ, x);
            } else {
                revert("You should chose First one");
            }
        }
        }else{
            revert("it's not in  QUEUED");
        }
    }

    function getId(uint256 _id) private view returns (uint256) {
        uint256 id = 0;

        for (uint256 i = 0; i < queue_Ids.length; i++) {
            if (queue_Ids[i] == _id) {
                id = i;
            }
        }

        return id;
    }

    function sendToExecution(uint256 proposalIndex, uint256[] memory datas)
        private
        returns (bool)
    {
        Proposal storage proposal = proposals[proposalIndex];

        if (
            proposal.buyToken == address(0xdead) &&
            proposal.sellToken != address(0xdead)
        ) {
            //sell

            execute_oneProposal(
                _Hash,
                proposal.amount,
                proposal.sellToken,
                true
            );
            proposal.activeState = State.EXECUTED;
        } else if (
            proposal.buyToken != address(0xdead) &&
            proposal.sellToken == address(0xdead)
        ) {
            //buy
            execute_oneProposal(
                _Hash,
                proposal.amount,
                proposal.buyToken,
                false
            );
            proposal.activeState = State.EXECUTED;
        } else {
            //struc
            if (datas.length == 3) {
                ReStructure(datas);
            } else {
                revert("more the 3 index");
            }
        }
    }

    function CheckOutVote(uint256 proposalIndex)
        public
        view
        returns (uint256, uint256)
    {
        Proposal storage proposal = proposals[proposalIndex];
        return (proposal.noVotes, proposal.yesVotes);
    }

    function OracleNext(uint256 proposalIndex, uint256[] memory x)
        public
        OnlyOracle
        returns (bool)
    {
        ProposalNext(proposalIndex, x);
        return true;
    }

    function ProposalNext(uint256 proposalIndex, uint256[] memory x)
        private
        returns (bool)
    {
        //voting
        //queue
        //excuteing

        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.activeState != State.FAILED, "State is FAILED");
        require(proposal.activeState != State.RUNNING, "State is FAILED");
        require(proposal.activeState != State.EXECUTED, "State is FAILED");

        //store data mapping and array
        uint8 signersNum = uint8(proposal.signers.length);

        if (signersNum >= signersRequired[uint8(proposal.proposalType)]) {
            if (proposal.proposalType == ProposalType.CASH_OUT) {
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }

                //if create => voiting
                //if voiting =>  time & voit ok?=> exuting  sendToExecution
                if (block.timestamp < proposal.date) {
                    revert("There is still time for the proposal");
                }
                if (proposal.noVotes >= 1 || proposal.yesVotes >= 1) {
                    if (proposal.noVotes > proposal.yesVotes) {
                        proposal.activeState = State.FAILED;
                        emit ProposalStatus(
                            proposal.creator,
                            proposalIndex,
                            proposal.sellToken,
                            proposal.buyToken,
                            State.FAILED
                        );
                        return true;
                    } else {
                        //
                        proposal.activeState = State.RUNNING;
                        executing_Ids.push(proposalIndex);
                        ProposalCheckOut(proposalIndex, x);
                        proposal.activeState = State.EXECUTED;
                        //send to supernova for running
                        return true;
                    }
                } else {
                    return false;
                }
            } else if (proposal.proposalType == ProposalType.DOUBLE_DOWN) {
                //ProposalInQueue
                //if create => voiting
                //if voiting =>  time & QUEUED ok?=> exuting = >ProposalCheckOut
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.QUEUED;
                    queue_Ids.push(proposalIndex);
                    return true;
                }

                if (_SupernovaBridge.balanceTreasury() <= DOUBLE_DEF) {
                    revert("Treasury is not ready");
                }
                if (proposal.activeState == State.QUEUED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }
                if (proposal.activeState == State.VOTING) {
                    if (block.timestamp < proposal.date) {
                        revert("There is still time for the proposal");
                    }
                    if (proposal.noVotes >= 1) {
                        if (proposal.noVotes > proposal.yesVotes) {
                            proposal.activeState = State.FAILED;
                            emit ProposalStatus(
                                proposal.creator,
                                proposalIndex,
                                proposal.sellToken,
                                proposal.buyToken,
                                State.FAILED
                            );
                            revert("FAILED");
                        } else {
                            proposal.activeState = State.RUNNING;
                            executing_Ids.push(proposalIndex);
                            ProposalCheckOut(proposalIndex, x);
                        }
                    } else {
                        return false;
                    }
                }

                return true;
            } else if (proposal.proposalType == ProposalType.CLASSIC) {
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.QUEUED;
                    queue_Ids.push(proposalIndex);
                    return true;
                }

                if (_SupernovaBridge.balanceTreasury() <= CLASSIC_MIN) {
                    revert("Treasury is not ready");
                }
                if (proposal.activeState == State.QUEUED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }

                if (proposal.activeState == State.VOTING) {
                    if (block.timestamp < proposal.date) {
                        revert("There is still time for the proposal");
                    }
                    if (proposal.noVotes >= 1) {
                        if (proposal.noVotes > proposal.yesVotes) {
                            proposal.activeState = State.FAILED;
                            emit ProposalStatus(
                                proposal.creator,
                                proposalIndex,
                                proposal.sellToken,
                                proposal.buyToken,
                                State.FAILED
                            );
                            revert("FAILED");
                        } else {
                            proposal.activeState = State.RUNNING;
                            executing_Ids.push(proposalIndex);
                            ProposalCheckOut(proposalIndex, x);
                        }
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            } else if (proposal.proposalType == ProposalType.STRUCTURE) {
                //STRUCTURE
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.QUEUED;
                    queue_Ids.push(proposalIndex);
                    return true;
                }

                if (proposal.activeState == State.QUEUED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }

                if (proposal.activeState == State.VOTING) {
                    if (block.timestamp < proposal.date) {
                        revert("There is still time for the proposal");
                    }
                    if (proposal.noVotes >= 1) {
                        if (proposal.noVotes > proposal.yesVotes) {
                            proposal.activeState = State.FAILED;
                            emit ProposalStatus(
                                proposal.creator,
                                proposalIndex,
                                proposal.sellToken,
                                proposal.buyToken,
                                State.FAILED
                            );
                            revert("FAILED");
                        } else {
                            proposal.activeState = State.RUNNING;
                            executing_Ids.push(proposalIndex);
                            ProposalCheckOut(proposalIndex, x);
                        }
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }

                return true;
            }
        } else {
            revert("signers Required");
        }
    }

    function FullCycleToExecution() public OnlyOracle returns (bool) {
        if (_SupernovaBridge.balanceTreasury() < FULLCYCLE_MAX) {
            revert("The amount is insufficient");
        }
        uint256 amount = _SupernovaBridge.balanceTreasury() - FULLCYCLE_MAX;
        execute_Cycle(_Hash, amount, _M87);
        return true;
    }

    function ReStructure(uint256[] memory arr) private returns (bool) {
        _FULLCYCLE = arr[0];
        MINIMUM = arr[1];
        VOTELIMIT = arr[2];

        return true;
    }

    function TreasuryBalance() public view returns (uint256) {
        uint256 r = _SupernovaBridge.balanceTreasury();
        return r;
    }

    //DAO execute
    function execute_oneProposal(
        bytes32 _hsh,
        uint256 _amount,
        address _token,
        bool _q
    ) internal Bridge(_hsh) returns (bool) {
        //checks

        //persentages

        // divid
        if (_q) {
            //token => eth
            //total* amount/10000
            (bool s, uint256 amount) = _SupernovaBridge.isSupportedToken(
                _token
            );
            uint256 val = (amount * _amount) / 10000;
            _amount = amount - val;
            swapTokensForEth(val, _token);
            uint256 getfromtoken = getAmountOutMinETH(_token, _amount);
            //transfer eth to _SupernovaBridge **
            (bool success, ) = address(_supernova).call{value: getfromtoken}(
                ""
            );
            _SupernovaBridge.PutOutTokenTreasuryB(
                _Hash,
                _amount,
                _token,
                1,
                0,
                0,
                getfromtoken
            );
            //1
            //swaping

            //afterswap divied to rewards
            //87% 12.7% .3%
            //  uint rewards = getfromtoken * 1300/10000 ; // 13%
            //  uint reward_1 = rewards * 30/10000 ; // 0.3%
            //  uint reward_2 = rewards - reward_1 ; // 12.7%
            //  getfromtoken = getfromtoken - rewards; //87%
            //  Reward_ETH_1 += reward_1;
            //  Reward_ETH_2 += reward_2;

            //2
        } else if (_q == false) {
            //eth => token
            //   before swap divied to rewards
            //  1
            //   afterswap divied to rewards
            //  87% 12.7% .3%
            swapETHForTokens(_amount, _token);

            uint256 getfromtoken = _amount;
            IERC20Upgradeable(_token).transfer(
                address(_supernova),
                getfromtoken
            );
            uint256 rewards = (getfromtoken * 1300) / 10000; // 13%
            uint256 reward_1 = (rewards * 870) / 10000; // 0.87%
            uint256 reward_2 = rewards - reward_1; // 12.3%
            getfromtoken = getfromtoken - rewards; //87%
            //token tranfer to _SupernovaBridge **

            _SupernovaBridge.PutOutTokenTreasuryB(
                _Hash,
                _amount,
                _token,
                2,
                reward_1,
                reward_2,
                getfromtoken
            );
            //2
        }
    }

    function execute_Cycle(
        bytes32 _hsh,
        uint256 _amount,
        address _token
    ) internal Bridge(_hsh) returns (bool) {
        //checks

        //persentages

        //eth => token
        //before swap divied to rewards
        //1
        swapETHForTokens(_amount, _token);

        uint256 getfromtoken = getAmountOutETHToken(_token, _amount);

        IERC20Upgradeable(_token).transfer(address(0xdead), getfromtoken);

        _SupernovaBridge.PutOutTokenTreasuryB(
            _Hash,
            _amount,
            _token,
            3,
            0,
            0,
            _amount
        );
    }

    /// SWAPs
    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) private {
        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp + 300
        );
    }

    function swapTokensForEth(uint256 amount, address _tokenIn) private {
        if (IERC20Upgradeable(_tokenIn).balanceOf(address(this)) < amount) {
            revert("Insufficient your balance!");
        }

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, amount);
        // make the swap
        IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp + 300
            );
    }

    function swapETHForTokens(uint256 amount, address _tokenIn) private {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);
        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, amount);
        // make the swap
        IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactETHForTokensSupportingFeeOnTransferTokens(
                amount,
                path,
                address(this),
                block.timestamp + 300
            );
    }

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256) {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function getAmountOutMinETH(address _tokenIn, uint256 _amountIn)
        internal
        view
        returns (uint256)
    {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = WETH;

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function getAmountOutETHToken(address _tokenIn, uint256 _amountIn)
        internal
        view
        returns (uint256)
    {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenIn;

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }
}