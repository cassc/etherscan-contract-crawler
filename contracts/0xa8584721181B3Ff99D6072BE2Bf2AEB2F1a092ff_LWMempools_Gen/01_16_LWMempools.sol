//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import './LTNT.sol';
import './lib/Rando.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';



/**

          ___  ___      ___        __   __        __  
|     /\   |  |__  |\ |  |   |  | /  \ |__) |__/ /__` 
|___ /~~\  |  |___ | \|  |  .|/\| \__/ |  \ |  \ .__/ 
                                                      
"mempools", latent.works, 2022


*/


/// @title Mempools
/// @author troels_a
/// @notice latent.works/mempools

contract LWMempools is ERC721, LTNTIssuer, Ownable, ReentrancyGuard {

    /// @dev main bank struct
    struct Bank {
        string _name; // name of bank
        string[4] _parts; // parts of the bank
        string _filter;
        uint[15] _pools;
    }

    uint public constant PRICE = 0.15 ether; // The price of one mempool

    uint private _pool_ids; // Tracks the current pool id
    Bank[15] private _banks; // Holds banks
    mapping(uint => uint) private _pool_timestamps; // Holds the timestamp of when a pool was created
    mapping(uint => uint) private _pool_banks; // Holds the bank id of a pool - id => bank_index
    mapping(uint => uint) private _pool_fixed_epochs; // Holds the fixed epoch of a pool - id => epoch

    LTNT public immutable _ltnt; // The LTNT token contract
    LWMempools_Gen public immutable _generator; // The generator contract
    LWMempools_Meta private _meta; // The meta contract


    //////////////////////////
    /// CONTRACT
    //////////////////////////

    constructor(address ltnt_) ERC721("Mempools", "MMPLS"){
        _ltnt = LTNT(ltnt_); // Set the LTNT token contract
        _generator = new LWMempools_Gen(); // Deploy the generator contract
        _meta = new LWMempools_Meta(); // Deploy the meta contract
    }

    /// @dev declare issuer info for LTNT
    /// @return LTNT.IssuerInfo struct with issuer info
    /// @param param_ the LTNT token params struct
    function issuerInfo(uint, LTNT.Param memory param_) public view override returns(LTNT.IssuerInfo memory){
        return LTNT.IssuerInfo('mempools', getPoolImage(param_._uint, true));
    }


    /// @dev get the address of the _meta contract
    /// @return address of the _meta contract
    function getMeta() public view returns (address){
        return address(_meta);
    }


    /// @dev set the address of the _meta contract
    /// @param meta_ the address of the new _meta contract
    function setMeta(address meta_) public onlyOwner {
        _meta = LWMempools_Meta(meta_);
    }




    /////////////////////////////
    /// MINTING
    /////////////////////////////


    /// @dev mint a new mempool
    /// @param bank_index_ the bank id of the mempool
    /// @param pool_index_ the pool id of the mempool
    function mint(uint bank_index_, uint pool_index_) public payable nonReentrant {
        uint bank_count_ = getBankCount();
        require(msg.value == PRICE, 'INVALID_PRICE'); // Check price
        require(bank_count_ > 0 && bank_index_ < bank_count_, 'INVALID_BANK'); // Check bank index
        require(_banks[bank_index_]._pools[pool_index_] == 0, 'POOL_INDEX_USED'); // Check pool index
        _mintFor(msg.sender, bank_index_, pool_index_); // Mint the mempool
    }


    /// @dev mint a new mempool holding a LTNT token
    /// @param ltnt_id_ the id of the LTNT token to hold
    /// @param bank_index_ the bank id of the mempool
    /// @param pool_index_ the pool id of the mempool
    function mintWithLTNT(uint ltnt_id_, uint bank_index_, uint pool_index_) public payable nonReentrant {
        uint bank_count_ = getBankCount();
        require(msg.value == (PRICE/3)*2, 'INVALID_PRICE'); // Check price
        require(_ltnt.ownerOf(ltnt_id_) == msg.sender, 'NOT_LTNT_HOLDER'); // Check LTNT ownership
        require(!_ltnt.hasStamp(ltnt_id_, address(this)), 'ALREADY_STAMPED'); // Check if LTNT is already stamped
        require(bank_count_ > 0 && bank_index_ < bank_count_, 'INVALID_BANK'); // Check bank index
        require(_banks[bank_index_]._pools[pool_index_] == 0, 'POOL_INDEX_USED'); // Check pool index
        uint id_ = _mintFor(msg.sender, bank_index_, pool_index_); // Mint the mempool
        _ltnt.stamp(ltnt_id_, LTNT.Param(id_, address(0), '', false)); // Stamp the LTNT token
    }


    /// @dev internal mint function
    function _mintFor(address for_, uint bank_, uint index_) private returns(uint) {
        _pool_ids++; // Increment the pool id
        _mint(for_, _pool_ids); // Mint the token
        _pool_timestamps[_pool_ids] = block.timestamp; // Set the timestamp of the pool
        _pool_banks[_pool_ids] = bank_; // Set the bank of the pool
        _banks[bank_]._pools[index_] = _pool_ids; // Set the pool id of the bank
        return _pool_ids;
    }


    /// @dev get the total supply of mempools
    /// @return uint total supply of mempools
    function totalSupply() public view returns (uint) {
        return _pool_ids;
    }


    /////////////////////////////
    /// BANKS
    /////////////////////////////


    /// @dev add a bank to the contract
    /// @param name_ the name of the bank
    /// @param parts_ the parts of the bank
    /// @param filter_ the filter of the bank
    function addBank(string memory name_, string[4] memory parts_, string memory filter_) public onlyOwner {

        uint next_index_ = getBankCount(); // Current count should be equal to next index since we start at 0
        require(next_index_ < _banks.length, "MAX_BANKS"); // Make sure we don't exceed the max banks
        
        _banks[next_index_]._name = name_; // Set the name
        _banks[next_index_]._parts = parts_; // Set the parts
        _banks[next_index_]._filter = filter_; // Set the filter

    }


    /// @dev get a specific bank
    /// @return Bank struct
    /// @param index_ the index of the bank in _banks
    function getBank(uint index_) public view returns(Bank memory){
        return _banks[index_];
    }


    /// @dev get array of added banks
    /// @return array of Bank structs
    function getBanks() public view returns(Bank[] memory){
        
        uint count = getBankCount(); // Get the bank count

        Bank[] memory banks_ = new Bank[](count); // Create a new array of banks with the correct length

        for(uint i = 0; i < count; i++) // Copy the banks to the new array
            banks_[i] = _banks[i];

        return banks_;

    }


    /// @dev get the cuurent count of banks
    /// @return uint the count
    function getBankCount() public view returns(uint) {

        uint count_; // Init the count
        for(uint i = 0; i < _banks.length; i++) // Loop through the banks
            if(bytes(_banks[i]._name).length > 0) // If the name is not empty
                count_++; // Increment the count

        return count_;
    }






    /////////////////////////////
    /// POOLS
    /////////////////////////////


    /// @dev check if a pool exists
    /// @return bool if the pool exists
    /// @param pool_id_ the id of the pool
    function poolExists(uint pool_id_) public view returns(bool) {
        return _exists(pool_id_);
    }


    /// @dev get the filter for a given pool
    /// @return string the name of the filter
    function getPoolFilter(uint pool_id_) public view returns(string memory){
        return _banks[_pool_banks[pool_id_]]._filter;
    }


    /// @dev get the bank index for a given pool
    /// @return uint the index of the bank
    /// @param pool_id_ the id of the pool
    function getPoolBankIndex(uint pool_id_) public view returns(uint){
        return _pool_banks[pool_id_];
    }


    /// @dev get the Bank struct for a given pool
    /// @return Bank the bank struct
    /// @param pool_id_ the id of the pool
    function getPoolBank(uint pool_id_) public view returns(LWMempools.Bank memory){
        return getBank(getPoolBankIndex(pool_id_));
    }


    /// @dev get the part index for a given pool
    /// @return uint the index of the part
    /// @param pool_id_ the id of the pool
    function getPoolPartIndex(uint pool_id_) public view returns(uint){
        Bank memory bank_ = getPoolBank(pool_id_);
        string memory seed_part_ = getPoolSeed(pool_id_, 'part');
        return Rando.number(seed_part_, 0, bank_._parts.length-1);
    }


    /// @dev get the part for a given pool
    /// @return string the part
    /// @param pool_id_ the id of the pool
    function getPoolPart(uint pool_id_) public view returns(string memory){
        LWMempools.Bank memory bank_ = getPoolBank(pool_id_);
        return bank_._parts[getPoolPartIndex(pool_id_)];
    }


    /// @dev get the seed for a given pool
    /// @return string the seed
    /// @param pool_id_ the id of the pool
    /// @param append_ a string to append to the seed
    function getPoolSeed(uint pool_id_, string memory append_) public view returns(string memory){
        return string(abi.encodePacked(Strings.toString(_pool_timestamps[pool_id_]), Strings.toString(pool_id_), append_));
    }





    /////////////////////////////
    /// EPOCHS
    /////////////////////////////

    /// @dev get epoch length for a given pool in seconds
    /// @return uint the epoch length
    /// @param pool_id_ the id of the pool
    function getEpochLength(uint pool_id_) public view returns(uint){
        return Rando.number(getPoolSeed(pool_id_, 'epoch'), 1, 6)*7776000;
    }


    /// @dev get the current epoch for a given pool
    /// @return uint the epoch number
    /// @param pool_id_ the id of the pool
    function getCurrentEpoch(uint pool_id_) public view returns(uint){
        uint epoch = (((block.timestamp - _pool_timestamps[pool_id_]) / getEpochLength(pool_id_))+1);
        return epoch;
    }


    /// @dev get the fixed epoch for a given pool
    /// @return uint the epoch number - 0 means the pool epoch is not fixed
    /// @param pool_id_ the id of the pool
    function getFixedEpoch(uint pool_id_) public view returns(uint){
        return _pool_fixed_epochs[pool_id_];
    }


    /// @dev allow pool owner to fix the epoch for a given pool
    /// @param pool_id_ the id of the pool
    /// @param epoch_ the epoch to fix the pool to
    function fixEpoch(uint pool_id_, uint epoch_) public {
        require(ownerOf(pool_id_) == msg.sender, 'NOT_OWNER');
        require(getCurrentEpoch(pool_id_) <= epoch_, 'EPOCH_NOT_REACHED');
        _pool_fixed_epochs[pool_id_] = epoch_;
    }





    /// @dev get the generated image for a pool
    /// @return string the image
    /// @param pool_id_ the id of the pool
    function getPoolImage(uint pool_id_, bool encode_) public view returns(string memory){

        if(!poolExists(pool_id_)) // If the pool doesn't exist...
            return ''; // ...return empty string

        uint epoch_ = _pool_fixed_epochs[pool_id_]; // Get the fixed epoch
        if(epoch_ < 1) // Fixed epoch is 0, go to current epoch
            epoch_ = getCurrentEpoch(pool_id_); // Get the current epoch

        return _generator.generateImage(pool_id_, epoch_, encode_); // Get the image based on id and epoch

    }


    /// @dev get the metadat data uri for a given pool
    /// @return string the uri
    /// @param pool_id_ the id of the pool
    function tokenURI(uint pool_id_) override public view returns(string memory) {
        return _meta.getJSON(pool_id_, true);
    }


    //////////////////////////
    /// BALANCE
    //////////////////////////

    function withdrawAllTo(address to_) public payable onlyOwner {
      require(payable(to_).send(address(this).balance));
    }

}


/// @title Mempools meta
/// @author troels_a
/// @notice This contract handles the metadata for the mempools contract
contract LWMempools_Meta {

    using Strings for string;

    LWMempools public _pools; // The mempools contract

    constructor() {
        _pools = LWMempools(msg.sender); // Set the mempools contract
    }
    
    /// @dev get the metadata for a given pool
    /// @return string the metadata
    /// @param pool_id_ the id of the pool
    function getJSON(uint pool_id_, bool encode_) public view returns(string memory) {
        
        if(!_pools.poolExists(pool_id_)) // If the pool doesn't exist...
            return ''; // ...return empty string

        LWMempools.Bank memory bank_ = _pools.getPoolBank(pool_id_); // Get the bank for the pool

        // Create the JSON string
        bytes memory json_ = abi.encodePacked(
            '{',
                '"name":"mempool #',Strings.toString(pool_id_),'",',
                '"image": "', _pools.getPoolImage(pool_id_, true),'",',
                '"description": "latent.works",',
                '"attributes": [',
                    '{"trait_type": "bank", "value": "',bank_._name,'"},',
                    '{"trait_type": "bank_index", "value": "',bank_._name,'-',Strings.toString(_pools.getPoolPartIndex(pool_id_)),'"},',
                    '{"trait_type": "epoch", "value": ', Strings.toString(_pools.getCurrentEpoch(pool_id_)), '},',
                    '{"trait_type": "fixed_epoch", "value": ', Strings.toString(_pools.getFixedEpoch(pool_id_)), '},',
                    '{"trait_type": "epoch_length", "value": ', Strings.toString(_pools.getEpochLength(pool_id_)), '}',
                ']',
            '}'
        );

        if(encode_) // If encode_ is true
            return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json_))); // ...encode the json string
        return string(json_); // return the raw JSON

    }


}


/// @title Mempools generator
/// @author troels_a
/// @notice Generates images for mempools
contract LWMempools_Gen {
    
    struct Pool {
        uint id;
        bytes items;
        string base;
        string seed;
        string seed1;
        string seed2;
        string filter;
        uint epoch;
        string shape1_width;
        string shape1_height;
        string shape2_width;
        string shape2_height;
        string shape3_width;
        string shape3_height;
    }

    LWMempools public immutable _pools; // The mempools contract

    constructor(){
        _pools = LWMempools(msg.sender); // Set the mempools contract
    }

    /// @dev generate an image for a given pool
    /// @return string the image
    /// @param pool_id_ the id of the pool
    /// @param epoch_ the epoch to generate the image for
    /// @param encode_ bool indicating if the image should be encoded as base64 or not
    function generateImage(uint pool_id_, uint epoch_, bool encode_) public view returns(string memory){

        if(!_pools.poolExists(pool_id_)) // If the pool doesn't exist...
            return ''; // ...return empty string

        Pool memory pool_; // Create a pool struct
        pool_.epoch = _pools.getCurrentEpoch(pool_id_); // Get the current epoch for pool

        if(epoch_ > pool_.epoch) // If the epoch input is higher than the current epoch...
            return ''; // ...return empty string
        
        pool_.id = pool_id_; // Set the pool id
        pool_.seed = _pools.getPoolSeed(pool_id_, ''); // Get the main seed for this pool
        pool_.base = _pools.getPoolPart(pool_id_); // Get the base part for this pool
        pool_.filter = _pools.getPoolFilter(pool_id_); // Get the filter for this pool


        /**
         * Create the shapes for each pool epoch
         */

        uint i;
        while(i < pool_.epoch){
            pool_.seed1 =_pools.getPoolSeed(pool_id_, string(abi.encodePacked('1x', Strings.toString(i))));
            pool_.seed2 = _pools.getPoolSeed(pool_id_, string(abi.encodePacked('1y', Strings.toString(i))));
            pool_.items = abi.encodePacked(
                pool_.items,
                '<use href="#shape',Strings.toString(Rando.number(pool_.seed1, 1, 3)),'" x="',Strings.toString(Rando.number(pool_.seed1, 1, 990)),'" y="',Strings.toString(Rando.number(pool_.seed2, 1, 900)),'" fill="url(#base',Strings.toString(Rando.number(pool_.seed2, 1, 5)),')"/>'
            );

            ++i;
        }

        i = 0;
        while(i < pool_.epoch){
            pool_.seed1 = _pools.getPoolSeed(pool_id_, string(abi.encodePacked('2x', Strings.toString(i))));
            pool_.seed2 = _pools.getPoolSeed(pool_id_, string(abi.encodePacked('2y', Strings.toString(i))));
            pool_.items = abi.encodePacked(
                pool_.items,
                '<use href="#shape',Strings.toString(Rando.number(pool_.seed1, 1, 3)),'" x="',Strings.toString(Rando.number(pool_.seed1, 1, 990)),'" y="',Strings.toString(Rando.number(pool_.seed2, 1, 900)),'" fill="url(#base',Strings.toString(Rando.number(pool_.seed2, 1, 5)),')"/>'
            );

            ++i;
        }

        i = 0;
        while(i < pool_.epoch){
            pool_.seed1 = _pools.getPoolSeed(pool_id_, string(abi.encodePacked('3x', Strings.toString(i))));
            pool_.seed2 = _pools.getPoolSeed(pool_id_, string(abi.encodePacked('3y', Strings.toString(i))));
            pool_.items = abi.encodePacked(
                pool_.items,
                '<use href="#shape',Strings.toString(Rando.number(pool_.seed1, 1, 3)),'" x="',Strings.toString(Rando.number(pool_.seed1, 1, 990)),'" y="',Strings.toString(Rando.number(pool_.seed2, 1, 900)),'" fill="url(#base',Strings.toString(Rando.number(pool_.seed2, 1, 5)),')"/>'
            );

            ++i;
        }

        /**
         * Create the shape dimensions
         */
        pool_.shape1_width = Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'shape1width'), 1, 50));
        pool_.shape1_height = Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'shape1height'), 20, 300));
        pool_.shape2_width = Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'shape2width'), 20, 30));
        pool_.shape2_height = Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'shape2height'), 20, 200));
        pool_.shape3_width = Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'shape2height'), 10, 30));
        pool_.shape3_height = Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'shape3width'), 20, 100));

        /**
         * Create the svg
         */
        bytes memory svg_ = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" preserveAspectRatio="xMinYMin meet">',
                '<defs>',
                    '<circle cx="500" cy="500" r="500" id="bg"/>',
                    '<filter id="none"><feColorMatrix in="SourceGraphic" type="saturate" values="0"/></filter>',
                    '<filter id="bw"><feColorMatrix type="matrix" values="0.491 1.650 0.166 0.000 -0.464 0.491 1.650 0.166 0.000 -0.464 0.491 1.650 0.166 0.000 -0.464 0.000 0.000 0.000 1.000 0.000"></feColorMatrix></filter>',
                    '<filter id="s1"><feColorMatrix in="SourceGraphic" type="saturate" values="2"/></filter>',
                    '<filter id="s2"><feColorMatrix in="SourceGraphic" type="saturate" values="4"/></filter>',
                    '<filter id="s3"><feColorMatrix in="SourceGraphic" type="saturate" values="6"/></filter>',
                    '<filter id="s4"><feColorMatrix in="SourceGraphic" type="saturate" values="8"/></filter>',
                    '<filter id="s5"><feColorMatrix in="SourceGraphic" type="saturate" values="10"/></filter>',
                    '<filter id="s6"><feColorMatrix in="SourceGraphic" type="saturate" values="12"/></filter>',
                    '<filter id="s7"><feColorMatrix in="SourceGraphic" type="saturate" values="14"/></filter>',
                    '<filter id="s8"><feColorMatrix in="SourceGraphic" type="saturate" values="16"/></filter>',
                    '<filter id="s9"><feColorMatrix in="SourceGraphic" type="saturate" values="18"/></filter>',
                    '<filter id="s10"><feColorMatrix in="SourceGraphic" type="saturate" values="20"/></filter>',
                    '<filter id="r1"><feColorMatrix in="SourceGraphic" type="hueRotate" values="20"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r2"><feColorMatrix in="SourceGraphic" type="hueRotate" values="40"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r3"><feColorMatrix in="SourceGraphic" type="hueRotate" values="60"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r4"><feColorMatrix in="SourceGraphic" type="hueRotate" values="80"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r5"><feColorMatrix in="SourceGraphic" type="hueRotate" values="100"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r6"><feColorMatrix in="SourceGraphic" type="hueRotate" values="120"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r7"><feColorMatrix in="SourceGraphic" type="hueRotate" values="140"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r8"><feColorMatrix in="SourceGraphic" type="hueRotate" values="160"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r9"><feColorMatrix in="SourceGraphic" type="hueRotate" values="180"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="r10"><feColorMatrix in="SourceGraphic" type="hueRotate" values="200"></feColorMatrix><feColorMatrix in="SourceGraphic" type="saturate" values="3"/></filter>',
                    '<filter id="internal-noise"><feTurbulence type="fractalNoise" baseFrequency="0.55" numOctaves="10" stitchTiles="stitch" /></filter>',
                    '<filter id="internal-blur" x="0" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="4" /></filter>',
                    '<clipPath id="clip"><use href="#bg"/></clipPath>',
                    '<rect id="shape1" width="',pool_.shape1_width,'" height="',pool_.shape1_height,'"/>',
                    '<rect id="shape2" width="30" height="',pool_.shape2_height,'"/>',
                    '<rect id="shape3" width="20" height="',pool_.shape3_height,'"/>',
                    '<image id="base" width="1000" height="1000" href="',pool_.base,'"/>',
                    '<pattern id="base1" x="0" y="0" width="1" height="1" viewBox="0 0 200 200"><use href="#base"/></pattern>',
                    '<pattern id="base2" x="0" y="0" width="1" height="1" viewBox="200 200 200 200" preserveAspectRatio="xMidYMid slice"><use href="#base"/></pattern>',
                    '<pattern id="base3" x="0" y="0" width="1" height="1" viewBox="400 400 200 200" preserveAspectRatio="xMidYMid slice"><use href="#base"/></pattern>',
                    '<pattern id="base4" x="0" y="0" width="1" height="1" viewBox="600 600 200 200" preserveAspectRatio="xMidYMid slice"><use href="#base"/></pattern>',
                    '<pattern id="base5" x="0" y="0" width="1" height="1" viewBox="800 800 200 200" preserveAspectRatio="xMidYMid slice"><use href="#base"/></pattern>',
                '</defs>',
                '<g filter="url(#',pool_.filter,')">',
                    '<rect width="1000" height="1000" fill="black"/>',
                    '<rect width="1000" height="1000" fill-opacity="0.5" fill="url(#base',Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'bg0'), 2, 5)),')" filter="url(#bw)"/>',
                    '<g clip-path="url(#clip)">',
                        '<use href="#bg" fill-opacity="1" fill="url(#base',Strings.toString(Rando.number(_pools.getPoolSeed(pool_.id, 'bg1'), 2, 5)),')"/>',
                    '<g filter="url(#internal-blur)" transform="translate(0, -100)" id="pool">',
                    pool_.items,
                    '</g>',
                    '<use href="#pool" transform="scale(.5, 0.5)"/>',
                    '<use href="#pool" transform="scale(.5, 0.5) translate(',Strings.toString(Rando.number(pool_.seed, 0, 100)),', 1000)"/>'
                    '<use href="#pool" transform="scale(0.8, 0.8) translate(1000, 0)"/>'
                    '<use href="#pool"  transform="scale(1, 1.5) translate(',Strings.toString(Rando.number(pool_.seed, 0, 500)),', ',Strings.toString(Rando.number(pool_.seed, 0, 500)),')"/>',
                    '</g>',
                    '<g filter="url(#bw)">',
                        '<rect width="1000" height="1000" fill="white" filter="url(#internal-noise)" opacity="0.15"/>',
                    '</g>',
                '</g>',
            '</svg>'
        );

        if(encode_) // encode the svg
            return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg_)));

        // return the raw svg
        return string(svg_);

    }


}