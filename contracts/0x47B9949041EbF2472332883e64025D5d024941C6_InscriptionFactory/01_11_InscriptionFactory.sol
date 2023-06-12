// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Inscription.sol";
import "./String.sol";
import "./TransferHelper.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InscriptionFactory is Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _inscriptionNumbers;

    uint8 public maxTickSize = 4;                   // tick(symbol) length is 4.
    uint256 public baseFee = 250000000000000;       // Will charge 0.00025 ETH as extra min tip from the second time of mint in the frozen period. And this tip will be double for each mint.
    uint256 public fundingCommission = 100;       // commission rate of fund raising, 100 means 1%

    mapping(uint256 => Token) private inscriptions; // key is inscription id, value is token data
    mapping(string => uint256) private ticks;       // Key is tick, value is inscription id

    event DeployInscription(
        uint256 indexed id, 
        string tick, 
        string name, 
        uint256 cap, 
        uint256 limitPerMint, 
        address inscriptionAddress, 
        uint256 timestamp
    );

    struct Token {
        string tick;            // same as symbol in ERC20
        string name;            // full name of token
        uint256 cap;            // Hard cap of token
        uint256 limitPerMint;   // Limitation per mint
        uint256 maxMintSize;    // // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint256 inscriptionId;  // Inscription id
        uint256 freezeTime;
        address onlyContractAddress;
        uint256 onlyMinQuantity;
        uint256 crowdFundingRate;
        address crowdfundingAddress;
        address addr;           // Contract address of inscribed token 
        uint256 timestamp;      // Inscribe timestamp
    }

    constructor() {
        // The inscription id will be from 1, not zero.
        _inscriptionNumbers.increment();
    }

    // Let this contract accept ETH as tip
    receive() external payable {}
    
    function deploy(
        string memory _name,
        string memory _tick,
        uint256 _cap,
        uint256 _limitPerMint,
        uint256 _maxMintSize, // The max lots of each mint
        uint256 _freezeTime, // Freeze seconds between two mint, during this freezing period, the mint fee will be increased 
        address _onlyContractAddress, // Only the holder of this asset can mint, optional
        uint256 _onlyMinQuantity, // The min quantity of asset for mint, optional
        uint256 _crowdFundingRate,
        address _crowdFundingAddress
    ) external returns (address _inscriptionAddress) {
        require(String.strlen(_tick) == maxTickSize, "Tick lenght should be 4");
        require(_cap >= _limitPerMint, "Limit per mint exceed cap");

        _tick = String.toLower(_tick);
        require(this.getIncriptionIdByTick(_tick) == 0, "tick is existed");

        // Create inscription contract
        bytes memory bytecode = type(Inscription).creationCode;
        uint256 _id = _inscriptionNumbers.current();
		bytecode = abi.encodePacked(bytecode, abi.encode(
            _name, 
            _tick, 
            _cap, 
            _limitPerMint, 
            _id, 
            _maxMintSize,
            _freezeTime,
            _onlyContractAddress,
            _onlyMinQuantity,
            baseFee,
            fundingCommission,
            _crowdFundingRate,
            _crowdFundingAddress,
            address(this)
        ));
		bytes32 salt = keccak256(abi.encodePacked(_id));
		assembly ("memory-safe") {
			_inscriptionAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
			if iszero(extcodesize(_inscriptionAddress)) {
				revert(0, 0)
			}
		}
        inscriptions[_id] = Token(
            _tick, 
            _name, 
            _cap, 
            _limitPerMint, 
            _maxMintSize,
            _id,
            _freezeTime,
            _onlyContractAddress,
            _onlyMinQuantity,
            _crowdFundingRate,
            _crowdFundingAddress,
            _inscriptionAddress, 
            block.timestamp
        );
        ticks[_tick] = _id;

        _inscriptionNumbers.increment();
        emit DeployInscription(_id, _tick, _name, _cap, _limitPerMint, _inscriptionAddress, block.timestamp);
    }

    function getInscriptionAmount() external view returns(uint256) {
        return _inscriptionNumbers.current() - 1;
    }

    function getIncriptionIdByTick(string memory _tick) external view returns(uint256) {
        return ticks[String.toLower(_tick)];
    }

    function getIncriptionById(uint256 _id) external view returns(Token memory, uint256) {
        Token memory token = inscriptions[_id];
        return (inscriptions[_id], Inscription(token.addr).totalSupply());
    }

    function getIncriptionByTick(string memory _tick) external view returns(Token memory tokens, uint256 totalSupplies) {
        Token memory token = inscriptions[this.getIncriptionIdByTick(_tick)];
        uint256 id = this.getIncriptionIdByTick(String.toLower(_tick));
        if(id > 0) {
            tokens = inscriptions[id];
            totalSupplies = Inscription(token.addr).totalSupply();
        }
    }

    function getInscriptionAmountByType(uint256 _type) external view returns(uint256) {
        require(_type < 3, "type is 0-2");
        uint256 totalInscription = this.getInscriptionAmount();
        uint256 count = 0;
        for(uint256 i = 1; i <= totalInscription; i++) {
            (Token memory _token, uint256 _totalSupply) = this.getIncriptionById(i);
            if(_type == 1 && _totalSupply == _token.cap) continue;
            else if(_type == 2 && _totalSupply < _token.cap) continue;
            else count++;
        }
        return count;
    }
    
    // Fetch inscription data by page no, page size, type and search keyword
    function getIncriptions(
        uint256 _pageNo, 
        uint256 _pageSize, 
        uint256 _type // 0- all, 1- in-process, 2- ended
    ) external view returns(
        Token[] memory, 
        uint256[] memory
    ) {
        // if _searchBy is not empty, the _pageNo and _pageSize should be set to 1
        require(_type < 3, "type is 0-2");
        uint256 totalInscription = this.getInscriptionAmount();
        uint256 pages = (totalInscription - 1) / _pageSize + 1;
        require(_pageNo > 0 && _pageSize > 0 && pages > 0 && _pageNo <= pages, "Params wrong");

        Token[] memory inscriptions_ = new Token[](_pageSize);
        uint256[] memory totalSupplies_ = new uint256[](_pageSize);

        Token[] memory _inscriptions = new Token[](totalInscription);
        uint256[] memory _totalSupplies = new uint256[](totalInscription);

        uint256 index = 0;
        for(uint256 i = 1; i <= totalInscription; i++) {
            (Token memory _token, uint256 _totalSupply) = this.getIncriptionById(i);
            if((_type == 1 && _totalSupply == _token.cap) || (_type == 2 && _totalSupply < _token.cap)) continue; 
            else {
                _inscriptions[index] = _token;
                _totalSupplies[index] = _totalSupply;
                index++;
            }
        }

        for(uint256 i = 0; i < _pageSize; i++) {
            uint256 id = (_pageNo - 1) * _pageSize + i;
            if(id < index) {
                inscriptions_[i] = _inscriptions[id];
                totalSupplies_[i] = _totalSupplies[id];
            } else break;
        }

        return (inscriptions_, totalSupplies_);
    }

    // Withdraw the ETH tip from the contract
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount <= payable(address(this)).balance);
        TransferHelper.safeTransferETH(_to, _amount);
    }

    // Update base fee
    function updateBaseFee(uint256 _fee) external onlyOwner {
        baseFee = _fee;
    }

    // Update funding commission
    function updateFundingCommission(uint256 _rate) external onlyOwner {
        fundingCommission = _rate;
    }

    // Update character's length of tick
    function updateTickSize(uint8 _size) external onlyOwner {
        maxTickSize = _size;
    }
}