// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Consensus {

    uint confirmationsRequired = 3;
    address[] public owners;
    
    struct ExecProposal{
        bytes32 uid;
        address to;
        string  func;
        bytes  data;
        uint timestamp;
        uint confirmations;
    }

    
    mapping(bytes32 => ExecProposal) public eps;
    mapping(bytes32 => bool) queue;
    mapping(bytes32 =>mapping(address =>bool)) public confirmations;
    mapping(address => bool) isOwner;

    modifier onlyOwner(){
        require(isOwner[msg.sender],"You are not the owner");
        _;
    }

    modifier onlyConsensus(){
        require(msg.sender == address(this),"Call the consensus function");
        _;
    }

    constructor(address[] memory _owners){
        require(_owners.length >= confirmationsRequired);
        for (uint i; i < _owners.length; i++){
            address nextOwner = _owners[i];

            require(!isOwner[nextOwner],"duplicated owner");

            isOwner[nextOwner] = true;
            owners.push(nextOwner);

        }
        
    }

    event queueTx(
        address sender,
        address to,
        string  func,
        bytes  data,
        uint timestamp,
        bytes32 txId
    );

    event discard(bytes32 txId);

    event executTx(
        address sender,
        bytes32 txId,
        uint timestamp,
        string func
    );
    //@dev Creating a transaction and adding to the queue for consideration
    function addExecProposal(
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external  onlyOwner returns(bytes32 _txId){
        
        bytes32 txId = txToByte(_func,_data,_timestamp);
        require(!queue[txId],"allready queue");

        queue[txId] = true;
        confirmations[txId][msg.sender] = true;
        eps[txId] = ExecProposal({
                uid : txId,
                to : address(this),
                func : _func,
                data : _data,
                timestamp : _timestamp,
                confirmations:1
                });

        emit queueTx(
            msg.sender,
            address(this),
            _func,
            _data,
            _timestamp,
            txId
        );
        
        return txId;
    }
    //@dev consent to send a transaction
    function confirm(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "not queued!");
        require(!confirmations[_txId][msg.sender], "already confirmed!");

        ExecProposal storage execProposal = eps[_txId];

        execProposal.confirmations++;
        confirmations[_txId][msg.sender] = true;

        if (execProposal.confirmations >= confirmationsRequired){
            execute(_txId);
        }
    }

    //@dev Cancellation of voting on a specific deal
    function cancelConfirmation(bytes32 _txId) external onlyOwner {
        require(confirmations[_txId][msg.sender], "not confirmed!");

        ExecProposal storage execProposal = eps[_txId];
        execProposal.confirmations--;
        confirmations[_txId][msg.sender] = false;

        if(execProposal.confirmations == 0){
            discardExecProposal(_txId);
        }
    }
    //@dev deleted a transaction
    function discardExecProposal(bytes32 _txId) private onlyOwner {
        require(queue[_txId], "not queued");
        
        delete queue[_txId];
        delete eps[_txId];
        for (uint i; i < owners.length;i++){
            confirmations[_txId][owners[i]] = false;
        }

        emit discard(_txId);
    }

    //@dev sending a transaction
    function execute(bytes32 txId) private onlyOwner {
        ExecProposal storage execProposal = eps[txId];

        require(queue[txId], "not queued");
        
        require(
            execProposal.confirmations >= confirmationsRequired,
            "not enough confirmations "
            );

        delete queue[txId];
        

        bytes memory data;
        data = abi.encodePacked(
                    bytes4(keccak256(bytes(execProposal.func))),
                    execProposal.data
        );

        (bool success, ) = address(this).call{value:0}(data);
        
        require(success,"tx error");
        
        delete eps[txId];
        
        emit executTx(msg.sender,txId,execProposal.timestamp,execProposal.func);

    }

    function txToByte(
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) internal view returns (bytes32 _txId){

        bytes32 txId = keccak256(abi.encode(
            address(this),
            _func,
            _data,
            _timestamp
        ));
        return txId;
    }

    function addOwner(address newOwner) public onlyConsensus{
        require(newOwner != address(0),"Error zero address");
        isOwner[newOwner] = true;
        owners.push(newOwner);
    }

    function delOwner(uint indexOwner) public {
        require(indexOwner <= owners.length,"Node index cannot be higher than their number"); // index must be less than or equal to array length
        require(owners.length -1  >= confirmationsRequired,"error minimal count owner");

        for (uint i = indexOwner; i < owners.length-1; i++){
            owners[i] = owners[i+1];
        }
        isOwner[owners[indexOwner]] = false;
        delete owners[owners.length-1];
        owners.pop();
    }

    function assignRequiredConf(uint _confReq) public onlyConsensus{
        require(owners.length >= _confReq,"error owners.length < _confReq");
        confirmationsRequired = _confReq;
    }

    function seeOwners() external view returns(address[] memory){
        return owners;
    }

    function seeMinCofReq() public view returns(uint){
        return confirmationsRequired;
    }


}
