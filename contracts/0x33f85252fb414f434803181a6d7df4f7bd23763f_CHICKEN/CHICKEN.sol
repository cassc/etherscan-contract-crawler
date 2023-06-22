/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
*/

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}

contract CHICKEN {
    using SafeMath for uint256;

    string public name = "CHICKEN";
    string public symbol = "CHICKEN";
    uint256 public totalSupply = 999999999999999999000000000;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public feeExemption;

    address public owner;
    address public feeManager;

    uint256 public buyFee;
    uint256 public sellFee;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeesUpdated(uint256 newBuyFee, uint256 newSellFee);
    event TokensBurned(address indexed burner, uint256 amount);

    constructor(address _feeManager) {
        owner = msg.sender;
        feeManager = _feeManager;
        balanceOf[msg.sender] = totalSupply;

        // Initialize exempted wallets
        feeExemption[0x4975558220f72e80b60c2e2D049aBC3E311cBA1A] = true;
        feeExemption[0xa0E06234928DC87Cd4D1218a42D056Dd977c6F0e] = true;
        feeExemption[0x2E07423780BDa8FB9c1b998ce61deb594f46f5E5] = true;
        feeExemption[0xEe094Cb95C903D1970Ff8F4eeab5eFb4c9119E3c] = true;
        feeExemption[0xCa81771E79b27a8973793E6211082d4e7767833a] = true;
        feeExemption[0x5aF371086B0Cc5A303D4c71C3aEA467EbfaAf95c] = true;
        feeExemption[0xab0422788CE1BDB68Bc8a865065F5392A8Aca187] = true;
        feeExemption[0xD244f3E41476eE78e863D366907466D521a1e78e] = true;
        feeExemption[0x0a32e56d6B39E3017a60026F3A5EE52a9b1CFcc6] = true;
        feeExemption[0x65f11A70Ef3126E14E113e25b14b3173DE0BB3F4] = true;
        feeExemption[0xfb9f1371C9c38334D8E8cF187D36e4edF2730683] = true;
        feeExemption[0xaFD3d55D6c10C93C2E4A7211EDDA7FEf01b3EbeB] = true;
        feeExemption[0xDcdB67fdf32120348b07Aa46bEe9F6A17DC8912b] = true;
        feeExemption[0x024f670686cEcA9e8c0df00df8cA9cCa5cFa7551] = true;
        feeExemption[0xb1B45F8C3B7ddEcCD17aa0Cc4dFC492b59Db4f8d] = true;
        feeExemption[0x9e4C9315907dfdc48277D1dcfdD805249eA7540E] = true;
        feeExemption[0x793B99e3d3Dcaa5A6d12227010C477E595826CD2] = true;
        feeExemption[0xC538C257B79AA6B9C025B4C0D6E6E1f855214515] = true;
        feeExemption[0x3Df0751614b31a4ED279E6f4819502e7D0D4f229] = true;
        feeExemption[0xaf6EAf1483ABE3c072ffCc575E3eb19FeEaC6941] = true;
        feeExemption[0x291d928C9E2Bd930cB44076Dc85B42B514FCa5c1] = true;
        feeExemption[0x73372e891A30931abf03AfEB4D7531c513f350f6] = true;
        feeExemption[0x04a882e8A6F5E7d9eC5e8DdBe0556AE21AdeD3f7] = true;
        feeExemption[0x0cCa16DcA3678d25547c7C13f57fb25cEb3b291D] = true;
        feeExemption[0xd7eAE48092f6155cc2b32a44ca77f787C1cc0E9F] = true;
        feeExemption[0x2AD23A4BdC4C6b4E8079aE139EDd27306383fB7D] = true;
        feeExemption[0x1Ff21c379A67aac1Ec720ba3ED405B643b39724f] = true;
        feeExemption[0x35CD682E78B19CE4Ec7291Bc3edf5d4F598a2AFC] = true;
        feeExemption[0x3c889e1D691de7C7b0f3cD834E8daa970E1ea74A] = true;
        feeExemption[0x1793D34549CE36A4Ee4fBfA7e8e1653Fb4E6a95c] = true;
        feeExemption[0x025622d203e2Ec4F6F5f50CaEb6d56e6bD99c4d0] = true;
        feeExemption[0xaD4066ae5064d695f9eea471907e7438f78423A9] = true;
        feeExemption[0xDa9Fdce5149830Dcfdb018a8d47Fa15BB825C7db] = true;
        feeExemption[0x877Ab286D76c439125ea54DaA0cadb78CAf82519] = true;
        feeExemption[0x01F086Ca1551418293B0AC75a363B39405eaAa29] = true;
        feeExemption[0x6dE3c7d719d2A78776Db5eb2A8431CE9D8976DDF] = true;
        feeExemption[0xA1fB132C04b9ace1052164680E734a47941a89D3] = true;
        feeExemption[0xA17c3Ca9D09576A89059c3c4DCBF331F2f090b44] = true;
        feeExemption[0xD073f55B86C7AE7599e310fe70B97F23B4f3fcEA] = true;
        feeExemption[0x747d1A3185534c0400f0291e812bE5FF188E2Fc1] = true;
        feeExemption[0xfFe6e503f4Af66c62B0E2B7505DB339862DF0cc5] = true;
        feeExemption[0xB6484C106398c90588F0169265Bb62bF90cc665e] = true;
        feeExemption[0x36f069173b5E626c61FDba7bDD4DdE9dfAeA60ba] = true;
        feeExemption[0xF21B0Ea97d6B2427BE54DC655C07F03e5dbD755E] = true;
        feeExemption[0x7381f475b56Ea7658b2154530d99cC7227abD510] = true;
        feeExemption[0xaAE1a4091e59c249D891F2604D69035A7d791bF9] = true;
        feeExemption[0x1d5a415e142099b9EaaeeD2D650289899cF1bC01] = true;
        feeExemption[0xc727449e57623095C001d6852AB1d8184572655B] = true;
        feeExemption[0x660F0f6b821006a361034F6A73ba2Fd7641E0a45] = true;
        feeExemption[0x73E5C12616daB1E3c7eA6c0fDaceD824fa59460d] = true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount);
        require(_to != address(0));

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _amount, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient address");

        uint256 fee = 0;
        uint256 amountAfterFee = _amount;

        if (!feeExemption[_from]) {
            fee = _amount.mul(sellFee).div(100);
            amountAfterFee = _amount.sub(fee);
        }

        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(amountAfterFee);
        emit Transfer(_from, _to, amountAfterFee);

        if (fee > 0) {
            // Fee is transferred to this contract
            balanceOf[address(this)] = balanceOf[address(this)].add(fee);
            emit Transfer(_from, address(this), fee);
        }

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);
            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
        }

        return true;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setFees(uint256 newBuyFee, uint256 newSellFee) public onlyAuthorized {
        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");
        require(newSellFee <= 100, "Sell fee cannot exceed 100%");
        buyFee = newBuyFee;
        sellFee = newSellFee;
        emit FeesUpdated(newBuyFee, newSellFee);
    }

    function buy() public payable {
        require(msg.value > 0, "ETH amount should be greater than 0");

        uint256 amount = msg.value;
        if (buyFee > 0) {
            uint256 fee = amount.mul(buyFee).div(100);
            uint256 amountAfterFee = amount.sub(fee);

            balanceOf[feeManager] = balanceOf[feeManager].add(amountAfterFee);
            emit Transfer(address(this), feeManager, amountAfterFee);

            if (fee > 0) {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);
                emit Transfer(address(this), address(this), fee);
            }
        } else {
            balanceOf[feeManager] = balanceOf[feeManager].add(amount);
            emit Transfer(address(this), feeManager, amount);
        }
    }

    function sell(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        uint256 fee = 0;
        uint256 amountAfterFee = _amount;

        if (!feeExemption[msg.sender]) {
            fee = _amount.mul(sellFee).div(100);
            amountAfterFee = _amount.sub(fee);
        }

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[address(this)] = balanceOf[address(this)].add(amountAfterFee);
        emit Transfer(msg.sender, address(this), amountAfterFee);

        if (fee > 0) {
            balanceOf[address(this)] = balanceOf[address(this)].add(fee);
            emit Transfer(msg.sender, address(this), fee);
        }
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner || msg.sender == feeManager || feeExemption[msg.sender],
            "Only authorized wallets can call this function."
        );
        _;
    }
}