// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HoneyPots is ERC1155, Ownable {
    // Keep track of generations
    using Counters for Counters.Counter;
    //In order to simplify things for clients we track generations with a counter.
    Counters.Counter public generationCounter;
    mapping(uint256 => uint256) public generations;

    // Contract whitelist
    mapping(address => bool) public contractWhitelist;

    uint256 public totalPower = 0;

    mapping(uint256 => uint256) public genTotalPower;

    uint public maxGenerations = 127;

    uint256 public _currentGeneration = 0;

    bool genLogicKS = false;

    bool public paused;

    // TODO: Change url to the production one
    constructor()
        ERC1155(
            "https://socialbees-mint.s3.amazonaws.com/honeypot/{id}"
        )
    {
        // Set the current generation
        generationCounter.increment();
        generations[generationCounter.current()] = generationCounter.current();
        _currentGeneration = generationCounter.current();
        paused = false;
    }
    function setBaseURI(string memory _value) public onlyOwner{
        _setURI(_value);
    }
    function setMaxGens(uint _value) public onlyOwner{
        maxGenerations = _value;
    }
    function setGenLogicKS(bool _value) public onlyOwner{
        genLogicKS = _value;
    }
    function mint(address _recipient, uint256 _amount)
        external
        onlyWhitelisted
    {
        require(!paused, "Contract is paused.");

        if(!genLogicKS){
            uint256 newPower = _amount * (2**(maxGenerations-_currentGeneration));
            totalPower += newPower;
            genTotalPower[_currentGeneration] += newPower;
        }

        _mint(_recipient, _currentGeneration, _amount, "");

    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        if(!genLogicKS){
            require(balanceOf(account, id) >= value);
            uint256 _power = value * (2**(maxGenerations-id));
            totalPower -= _power;
            genTotalPower[id] -= _power;
        }
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        if(!genLogicKS){
            require(values.length == ids.length, "ERC1155: values and ids length mismatch");

            for (uint256 i = 0; i < values.length; ++i) {
                require(ids[i] <= maxGenerations);
                require(balanceOf(account, ids[i]) >= values[i]);
                
                uint256 _power = values[i] * (2**(maxGenerations-ids[i]));
                totalPower -= _power;
                genTotalPower[ids[i]] -= _power;
            }
        }
        _burnBatch(account, ids, values);

    }

    function powerBalanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        require(id <= maxGenerations);
        return balanceOf(account, id) * (2**(maxGenerations-id));
    }

    function powerBalanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(ids[i] < maxGenerations);

            batchBalances[i] = balanceOf(accounts[i], ids[i]) * (2**(maxGenerations-ids[i]));
        }

        return batchBalances;
    }

    // Adds a new generation
    function addGeneration() external onlyOwner {
        require(generationCounter.current() <= maxGenerations, "Max generations reached");
        generationCounter.increment();
        generations[generationCounter.current()] = generationCounter.current();
    }

    function currentGeneration() public view returns (uint256) {
        return _currentGeneration;//generationCounter.current();
    }

    function currentGenerationCount() public view returns (uint256) {
        return generationCounter.current();
    }

    function setCurrentGeneration(uint256 _value) external onlyOwner{
        require(_value <= generationCounter.current(), "Gen out of bounds");
        _currentGeneration = _value;
    }

    function whitelistContract(address _contract, bool _whitelisted)
        external
        onlyOwner
    {
        contractWhitelist[_contract] = _whitelisted;
    }

    function isWhitelisted(address _contract) public view returns (bool) {
        return contractWhitelist[_contract];
    }

    function pauseContract(bool _paused) external onlyOwner {
        paused = _paused;
    }

    modifier onlyWhitelisted() {
        require(contractWhitelist[msg.sender], "Not whitelisted.");
        _;
    }
}