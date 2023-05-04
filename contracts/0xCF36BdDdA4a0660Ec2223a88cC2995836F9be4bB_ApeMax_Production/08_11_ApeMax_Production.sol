// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Libraries/Constants.sol";
import "./Libraries/Data_Structures.sol";
import "./Libraries/Helper_Functions.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
    Production version of ApeMax Token
*/

contract ApeMax_Production is ERC20Upgradeable, OwnableUpgradeable {

    // ------- Events -------
    event _mint_apemax(address indexed recipient_address, uint128 amount_minted, uint128 amount_paid, uint32 timestamp, uint8 currency_index);
    event _stake_tokens(address indexed staker_address, address indexed stake_address, uint64 indexed contract_index, uint128 amount_staked, uint32 timestamp);
    event _unstake_tokens(address indexed staker_address, address indexed stake_address, uint64 indexed contract_index, uint128 amount_staked, uint32 timestamp);
    event _claim_staking_rewards(address indexed staker_address, address indexed stake_address, uint64 indexed contract_index, uint128 amount_claimed, uint32 timestamp);
    event _create_staking_contract(address indexed contract_address, uint64 indexed contract_index, address indexed owner_address, uint32 timestamp);
    event _claim_creator_rewards(address indexed contract_address, uint64 indexed contract_index, address indexed owner_address, uint128 amount_claimed, uint32 timestamp);
    event _update_royalties(address indexed contract_address, uint64 indexed contract_index, address indexed owner_address, uint16 royalties, uint32 timestamp);
    event _distribute_rewards(address indexed contract_address, uint64 indexed contract_index, uint128 reward_amount, uint160 reward_units, uint32 timestamp);

    // ------- Global Vars -------
    Data_Structures.Global internal Global;
    mapping(uint64 => Data_Structures.Contract) internal Contracts;
    mapping(address => Data_Structures.Stake) internal Stakes;

    // For convenience
    mapping(address => uint64) internal Address_To_Contract;
    mapping(address => bool) internal Whitelisted_For_Transfer;

    // Contract State / Rules
    bool transfers_allowed;

    // ------- Init -------
    function initialize() public initializer {

        // Describe the token
        __ERC20_init("ApeMax", "APEMAX");
        __Ownable_init();

        // Mint to founders wallets
        _mint(Constants.founder_0, Constants.founder_reward);
        _mint(Constants.founder_1, Constants.founder_reward);
        _mint(Constants.founder_2, Constants.founder_reward);
        _mint(Constants.founder_3, Constants.founder_reward);

        // Mint to the company wallet
        _mint(Constants.company_wallet, Constants.company_reward);

        // Mint to the contract
        _mint(address(this), Constants.maximum_subsidy);

        // Init global vars
        Global.random_seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty
        )));

        Global.init_time = uint32(block.timestamp);

    }

    // ------- Presale -------
    function mint_apemax(
        address recipient,

        uint128 amount_payable,
        uint128 quantity,
        uint32 timestamp,
        
        uint8 currency_index, // 0 = eth, 1 = usdt, 2 = usdc, 3 = credit card in eth

        uint8 v, bytes32 r, bytes32 s // <-- signature
        
        )
        public payable
    {

        // Check signature and other params
        Helper_Functions.verify_minting_authorization(
            Global.total_minted,
            block.timestamp,
            amount_payable,
            quantity,
            timestamp,
            currency_index,
            v, r, s
        );
        
        

        // Price checks        
        if (currency_index == 1) {
            IERC20Upgradeable usdt = IERC20Upgradeable(Constants.usdt_address);
            require(usdt.transferFrom(msg.sender, address(this), amount_payable), "USDT token transfer failed");
        }
        else if (currency_index == 2) {
            IERC20Upgradeable usdc = IERC20Upgradeable(Constants.usdc_address);
            require(usdc.transferFrom(msg.sender, address(this), amount_payable), "USDC token transfer failed");
        }
        else {
            // Added 1% tolerance
            uint128 one_percent_less = amount_payable - amount_payable / 100;
            require(msg.value >= one_percent_less, "Incorrect ETH amount sent");
        }

        

        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        // Update quantities
        Global.total_minted += quantity;
        _mint(recipient, quantity);

        // Emit event
        emit _mint_apemax(recipient, quantity, amount_payable, uint32(block.timestamp), currency_index);

    }

    // ------- Transfers -------
    function transfer(
        address recipient,
        uint256 amount
        )
        public override
        can_transfer(msg.sender, recipient)
        has_sufficient_balance(msg.sender, amount)
        returns (bool)
    {

        // Calculate tax that is owed
        uint128 tax_rate = Helper_Functions.calculate_tax(Global.total_staked);
        uint128 tax_amount = uint128(amount) * tax_rate / 10000;
        
        // Transfer to this contract and to recipient accordingly
        _transfer(msg.sender, address(this), tax_amount);

        // Distribute rewards accordingly
        distribute_rewards(
            tax_amount
        );

        // Execute normal transfer logic on difference
        return super.transfer(recipient, amount-tax_amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
        )
        public override
        can_transfer(sender, recipient)
        has_sufficient_balance(msg.sender, amount)
        has_sufficient_allowance(msg.sender, amount)
        returns (bool)
    {

        // Calculate tax that is owed
        uint128 tax_rate = Helper_Functions.calculate_tax(Global.total_staked);
        uint128 tax_amount = uint128(amount) * tax_rate / 10000;
        
        // Transfer to this contract and to recipient accordingly
        _transfer(sender, address(this), tax_amount);

        // Distribute rewards accordingly
        distribute_rewards(
            tax_amount
        );

        // Execute normal transfer from logic on difference
        return super.transferFrom(sender, recipient, amount-tax_amount);
    }
    


    // ------- Staking -------
    function stake_tokens(
        uint128 amount_staked,
        uint64 contract_index,
        address stake_address
        )
        public
        has_sufficient_balance(msg.sender,amount_staked)
        contract_exists(contract_index)
        stake_address_unused(stake_address)
    {

        _transfer(msg.sender, address(this), amount_staked);

        Data_Structures.Contract storage Contract = Contracts[contract_index];

        // Calculate fees
        Data_Structures.Split memory Split = Helper_Functions.calculate_inbound_fees(
            amount_staked,
            Contract.royalties,
            Global.total_staked
        );

        // Add fees to creator and minsterial 
        Contract.unclaimed_creator_rewards += Split.creator;
        Global.unclaimed_ministerial_rewards += Split.ministerial;

        // Distribute rewards accordingly
        distribute_rewards(
            Split.tax
        );

        // Get actual amount being staked
        uint128 amount_sub_fees = amount_staked - Split.total;

        // Setup a new stake
        Data_Structures.Stake memory Stake;
        Stake.amount_staked = amount_sub_fees;
        Stake.amount_staked_raw = amount_staked;
        Stake.staker_address = msg.sender;
        Stake.init_time = uint32(block.timestamp);

        
        if (Contract.total_staked != 0) {

            // Calculate delay nerf
            Stake.delay_nerf = Helper_Functions.delay_function(
                Contract.total_staked,
                Global.total_staked,
                Global.contract_count
            );
        
            // Handle finders fees
            Contract.total_multiple += uint160(amount_sub_fees) * uint160(Constants.decimals) / uint160(Contract.total_staked);
            Stake.multiple = Contract.total_multiple;
        }

        // Update the rest of the stuff
        Stake.historic_reward_units = Contract.reward_units;

        Stake.contract_index = contract_index;

        // Index Stake in Stakes struct on account --> stake address --> Stake...
        Stakes[stake_address] = Stake;

        // Update Contract
        Contract.total_staked += amount_sub_fees;

        // Update Global
        Global.total_staked += amount_sub_fees;

        // Emit event
        emit _stake_tokens(msg.sender, stake_address, contract_index, amount_sub_fees, uint32(block.timestamp));

    }

    function unstake_tokens(
        address stake_address,
        uint64 contract_index
        )
        public
        contract_exists(contract_index)
        stake_address_exists(stake_address)
    {

        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        // Claim any outstanding rewards
        claim_staking_rewards(
            stake_address,
            contract_index
        );

        Data_Structures.Stake storage Stake = Stakes[stake_address];
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        // Decrement everything
        // Update Contract
        Contract.total_staked -= Stake.amount_staked;

        // Return the user his stake amount
        _transfer(address(this), msg.sender, Stake.amount_staked);

        // Update Global
        Global.total_staked -= Stake.amount_staked;

        // Emit event
        emit _unstake_tokens(msg.sender, stake_address, contract_index, Stake.amount_staked, uint32(block.timestamp));

        // Delete stake
        Stake.amount_staked = 0;

    }


    function claim_staking_rewards(
        address stake_address,
        uint64 contract_index
        )
        public
        contract_exists(contract_index)
        stake_address_exists(stake_address)
    {

        // Create storage / pointer references to make code cleaners
        Data_Structures.Stake storage Stake = Stakes[stake_address];
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        // Exit early if no claim so state is not affected
        uint32 time_elapsed = uint32(block.timestamp) - Stake.init_time;
        if (time_elapsed < Stake.delay_nerf) {
            return;
        }

        // Get finders fees owed
        uint160 relevant_multiple = Contract.total_multiple - Stake.multiple;
        uint256 finders_fees =
            relevant_multiple *
            Stake.amount_staked_raw *
            Constants.finders_fee / 10000
            / Constants.decimals;

        // Update multiple to current
        Stake.multiple = Contract.total_multiple;

        // Get relevant portions for computation
        uint160 relevant_units =
            Contract.reward_units -
            Stake.historic_reward_units;
        
        // Update back to latest historic values
        Stake.historic_reward_units = Contract.reward_units;
 
        // Compute rewards
        uint256 rewards = 
            Stake.amount_staked *
            relevant_units /
            Constants.decimals;

        // Add in finders fees
        rewards += finders_fees;
     

        // Nerf rewards for delay only for the first claim
        if (Stake.has_been_delay_nerfed == false) {

            uint256 nerfed_rewards =
                rewards *
                (time_elapsed - Stake.delay_nerf) /
                time_elapsed;
            
            Global.unclaimed_ministerial_rewards += uint128(rewards - nerfed_rewards);

            rewards = nerfed_rewards;

            Stake.has_been_delay_nerfed = true;
        }

        // Send rewards
        _transfer(address(this), msg.sender, rewards);

        // Emit event
        emit _claim_staking_rewards(msg.sender, stake_address, contract_index, uint128(rewards), uint32(block.timestamp));

    }

    // ------- For Creators -------
    function create_staking_contract(
        address contract_address,
        address owner_address,
        uint16 royalties
        )
        public
        contract_unused(contract_address)
        onlyOwner // <-- will be updated after the presale
    {   

        // Init a new contract
        Data_Structures.Contract memory Contract;

        // Correct royalties to range and set
        Contract.royalties = Helper_Functions.fix_royalties(royalties);

        // Set contract address
        Contract.contract_address = contract_address;

        // Set owner address
        Contract.owner_address = owner_address;

        // Index contract in struct
        Contracts[Global.contract_count] = Contract;

        // For convenience
        Address_To_Contract[contract_address] = Global.contract_count;

        // Emit event
        emit _create_staking_contract(contract_address, Global.contract_count, owner_address, uint32(block.timestamp));
        
        // Increment total count of contracts
        Global.contract_count++;
    }

    function update_contract_owner(
        uint64 contract_index,
        address owner_address
        )
        public
        contract_exists(contract_index)
        only_address_owner(Contracts[contract_index].contract_address, Contracts[contract_index].owner_address)
    {
        Data_Structures.Contract storage Contract = Contracts[contract_index];
        Contract.owner_address = owner_address;
    }

    function claim_creator_rewards(
        uint64 contract_index
        )
        public
        contract_exists(contract_index)
        only_address_owner(Contracts[contract_index].contract_address, Contracts[contract_index].owner_address)
    {
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        _transfer(address(this), msg.sender, Contract.unclaimed_creator_rewards);
        
        // Emit event
        emit _claim_creator_rewards(Contract.contract_address, contract_index, Contract.owner_address, Contract.unclaimed_creator_rewards, uint32(block.timestamp));

        Contract.unclaimed_creator_rewards = 0;
    }

    function update_royalties(
        uint64 contract_index,
        uint16 royalties
        )
        public
        contract_exists(contract_index)
        only_address_owner(Contracts[contract_index].contract_address, Contracts[contract_index].owner_address)
    {
        // Distribute rewards accordingly
        distribute_rewards(
            0
        );

        Data_Structures.Contract storage Contract = Contracts[contract_index];

        Contract.royalties = royalties;

        // Emit event
        emit _update_royalties(Contract.contract_address, contract_index, Contract.owner_address, royalties, uint32(block.timestamp));

    }

    // ------- Ministerial -------
    function withdraw_currency(uint8 currency_index) public onlyOwner {

        if (currency_index == 0) {
            require(address(this).balance > 0, "Insufficient balance");
            payable(owner()).transfer(address(this).balance);
        }
        else if (currency_index == 1) {
            IERC20Upgradeable usdt = IERC20Upgradeable(Constants.usdt_address);
            uint256 usdt_balance = usdt.balanceOf(address(this));
            require(usdt.transfer(owner(), usdt_balance), "USDT token transfer failed");
        }
        else if (currency_index == 2) {
            IERC20Upgradeable usdc = IERC20Upgradeable(Constants.usdc_address);
            uint256 usdc_balance = usdc.balanceOf(address(this));
            require(usdc.transfer(owner(), usdc_balance), "USDC token transfer failed");
        }
        
    }

    function claim_ministerial_rewards()
        public
        onlyOwner
    {
        _transfer(address(this), owner(), Global.unclaimed_ministerial_rewards);
        Global.unclaimed_ministerial_rewards = 0;
    }

    function enable_transfers(bool _transfers_allowed) public {
        transfers_allowed = _transfers_allowed;
    }

    function whitelist_address_for_transfer(address whitelisted_address, bool status) public {
        Whitelisted_For_Transfer[whitelisted_address] = status;
    }

    function batch_create_staking_contract(
        address[] memory contract_addresses,
        address[] memory owner_addresses,
        uint16[] memory royalties
        )
        public
        onlyOwner
    {
        for (uint256 index = 0; index < contract_addresses.length; index++) {
            create_staking_contract(
                contract_addresses[index],
                owner_addresses[index],
                royalties[index]
            );
        }
    }


    // ------- Internal Helpers -------
    function distribute_rewards(
        uint128 extra_reward
        )
        internal
    {
        // Get subsidy rewards
        uint128 subsidy_amount = Helper_Functions.calculate_subsidy_for_range(
            Global.last_subsidy_update_time,
            uint32(block.timestamp),
            Global.init_time
        );

        // Update last time we calculated subsidy
        Global.last_subsidy_update_time = uint32(block.timestamp);

        // Nerf the subsidy by the mint ratio
        // Add 25% cap within the mint nerf compared to amount stake
        uint256 mint_nerf_ratio = Global.total_minted > 4 * Global.total_staked ? uint256(4 * Global.total_staked) : uint256(Global.total_minted);
        uint128 claimed_subsidy_amount = uint128(uint256(subsidy_amount) * mint_nerf_ratio / uint256(Constants.max_presale_quantity));

        Global.nerfed_subsidy += subsidy_amount - claimed_subsidy_amount;

        uint128 current_weight = 0;
        uint64 contract_index = 0;
        bool found_index = false;

        for (uint8 i = 0; i < 3; i++) {
            
            // Get a random source
            Global.random_seed = uint256(keccak256(abi.encodePacked(
                Global.random_seed,
                Global.total_staked,
                extra_reward,
                block.difficulty
            )));

            // Convert to index, allowing 2 extra indexes which are going to default to total_staked = 0
            uint64 index = uint64(Global.random_seed % uint256(Global.contract_count+2));

            if (index >= Global.contract_count) {
                continue;
            }

            found_index = true;
 
            // Use greater equal so that if total staked is 0 for all chosen (somehow?) then it still will select something and not always index 0
            if (Contracts[index].total_staked >= current_weight) {
                current_weight = Contracts[index].total_staked;
                contract_index = index;
            }

        }

        if (found_index == false) {
            contract_index = uint64(Global.random_seed % uint256(Global.contract_count));
        }


        // Update based on the choice
        Data_Structures.Contract storage Contract = Contracts[contract_index];

        uint128 total_reward = claimed_subsidy_amount + extra_reward;

        if (Contract.total_staked != 0) {

            uint128 staker_rewards =
                (10000 - Contract.royalties) *
                total_reward /
                10000;

            Contract.reward_units +=
                uint160(Constants.decimals) *
                uint160(staker_rewards) / 
                uint160(Contract.total_staked);

            Contract.unclaimed_creator_rewards +=
                total_reward -
                staker_rewards;

        }
        else {
            // If there is nothing staked, everything goes to the owner
            Contract.unclaimed_creator_rewards += total_reward;
        }

        // Emit event
        emit _distribute_rewards(Contract.contract_address, contract_index, total_reward, Contract.reward_units, uint32(block.timestamp));
        
    }

    // ------- Internal Modifiers -------
    modifier only_address_owner(address contract_address, address owner_address) {

        // Check if the sender is the owner of ApeMax contract
        // or if this is an EOA, we will also allow the msg.sender == contract_address
        // or if is type ownable then we also check

        require(
            msg.sender == owner() ||
            msg.sender == contract_address ||
            msg.sender == owner_address,
            "Unauthorized Access"
        );

        _;
    }

    modifier contract_exists(uint64 contract_index) {
        require(
            Contracts[contract_index].contract_address != address(0),
            "No staking contract found at index"
        );
        _;
    }

    modifier contract_unused(address contract_address) {
        require(
            contract_address != address(0),
            "Invalid address"
        );

        require(
            Address_To_Contract[contract_address] == 0 &&
            Contracts[0].contract_address != contract_address,
            "Address already indexed for staking"
        );
        _;
    }

    modifier stake_address_exists(address stake_address) {
        require(
            Stakes[stake_address].staker_address == msg.sender,
            "Stake does not belong to sender"
        );

        require(
            Stakes[stake_address].amount_staked != 0 &&
            Stakes[stake_address].staker_address != address(0),
            "Staking address doesnt exist"
        );
        _;
    }

    modifier stake_address_unused(address stake_address) {
        require(
            stake_address != address(0),
            "Invalid staking address"
        );

        require(
            Stakes[stake_address].amount_staked == 0 &&
            Stakes[stake_address].staker_address == address(0),
            "Staking address already in use"
        );
        _;
    }

    modifier has_sufficient_balance(address sender, uint256 amount_required) {
        require(
            balanceOf(sender) >= amount_required,
            "Insufficient balance"
        );
        _;
    }

    modifier has_sufficient_allowance(address sender, uint256 amount_required) {
        require(
            allowance(sender, address(this)) >= amount_required,
            "Insufficient allowance"
        );
        _;
    }

    modifier can_transfer(address sender, address recipient) {
        require(
            transfers_allowed ||
            recipient == address(this) ||
            Whitelisted_For_Transfer[sender] == true,
            "Transfers are not authorized during the presale"
        );
        _;
    }    
    
    // ------- Readonly -------
    function get_contract(
        uint64 contract_index
        )
        public view
        returns (Data_Structures.Contract memory)
    {
        return Contracts[contract_index];
    }

    function get_stake(
        address stake_address
        )
        public view
        returns (Data_Structures.Stake memory)
    {
        return Stakes[stake_address];
    }

    function get_global()
        public view
        returns (Data_Structures.Global memory)
    {
        return Global;
    }   

}