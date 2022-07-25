pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

/**
 * @title Regular Companies v1.0 
 */

import "./Random.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// "special" companies are for a set of Regular IDs that share a trait, like McD's workers
// "not-special" companies get assigned to regular IDs randomly.

contract Companies is AccessControl {
    using Random for Random.Manifest;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant SALARY_DECIMALS = 2;
    uint public SALARY_MULTIPLIER = 100;                   // basis points

    struct Company {     
        uint128 baseSalary;   
        uint128 capacity;        
    }

    Company[60] companies;                                  // Companies by ID
    uint16[60] indexes;                                     // the starting index of the company in array of job IDs
    uint16[60] counts;
    Random.Manifest private mainDeck;                       // Card deck for non-special companies
    mapping(uint => Random.Manifest) private specialDecks;  // Card decks for special companies
    mapping(uint => uint) private specialCompanyIds;        // Company ID by special reg ID
    uint specialCompanyIdFlag;                              // Company ID for the first special company in the array
    uint[] _tempArray;                                      // used for parsing special IDs
    mapping(uint => bool) managerIds;                       // IDs of all McD's manager regs
    mapping(uint => string) names;                          // Company Names

    event jobIDCreated (uint256 regularId, uint newJobId, uint companyId, address sender);
    
	constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);

// Save Names

        names[0] = "RNN News";
        names[1] = "AAAARP";
        names[2] = "Petstore";
        names[3] = "Foodtime";
        names[4] = "Hats";
        names[5] = "Bed Bath & Bodyworks";
        names[6] = "Bugs Inc.";
        names[7] = "Autoz";
        names[8] = "Office Dept.";
        names[9] = "Express";
        names[10] = "Totally Wine";
        names[11] = "Y'all";
        names[12] = "5 O'clockville";
        names[13] = "Nrfthrup Grrmng";
        names[14] = "Mall Corp.";
        names[15] = "Ice Creams";
        names[16] = "Thanky Candles";
        names[17] = "Hotella";
        names[18] = "Berkshire Thataway";
        names[19] = "Kopies";
        names[20] = "Sprayers";
        names[21] = "'Onuts";
        names[22] = "Tax Inc.";
        names[23] = "Khols";
        names[24] = "Black Pebble";
        names[25] = "Haircuts Inc.";
        names[26] = "Global Gas";
        names[27] = "Block";
        names[28] = "Eyeglasses";
        names[29] = "Books & Mags";
        names[30] = "Meme";
        names[31] = "Coin";
        names[32] = "Wonder";
        names[33] = "iSecurity";
        names[34] = "Dairy Lady";
        names[35] = "Big Deal MGMT";
        names[36] = "Spotlight Talent";
        names[37] = "Rock Solid Insurance";
        names[38] = "Safe Shield Insurance";
        names[39] = "Bit";
        names[40] = "Whoppy Jrs.";
        names[41] = "WGMI Inc.";
        names[42] = "Global International";
        names[43] = "N.E.X.T. Rugs";
        names[44] = "Alpha Limited";
        names[45] = "Best Shack";
        names[46] = "Partners & Partners";
        names[47] = "Boss E-systems";
        names[48] = "Blockbusters";
        names[49] = "Hexagon Research Group";
        names[50] = "Crabby Shack";
        names[51] = "Dollar Store";
        names[52] = "UP Only";
        names[53] = "Frito Pay";
        names[54] = "Hot Pockets";
        names[55] = "Spooky";
        names[56] = "GM";
        names[57] = "McDanny's";
        names[58] = "Wendy's";
        names[59] = "Party Place";     
      
// Init companies
        
        companies[0] =  Company({ capacity : 212, baseSalary : 1950 });
        companies[1] =  Company({ capacity : 350, baseSalary : 1300 });
        companies[2] =  Company({ capacity : 120, baseSalary : 3725 });
        companies[3] =  Company({ capacity : 144, baseSalary : 3175 });
        companies[4] =  Company({ capacity : 168, baseSalary : 2375 });
        companies[5] =  Company({ capacity : 160, baseSalary : 2475 });
        companies[6] =  Company({ capacity : 100, baseSalary : 4400 });
        companies[7] =  Company({ capacity : 184, baseSalary : 2200 });
        companies[8] =  Company({ capacity : 500, baseSalary : 1025 });
        companies[9] =  Company({ capacity : 188, baseSalary : 2150 });
        companies[10] = Company({ capacity : 140, baseSalary : 3250 });
        companies[11] = Company({ capacity :  96, baseSalary : 4575 });
        companies[12] = Company({ capacity :  50, baseSalary : 7550 });
        companies[13] = Company({ capacity : 192, baseSalary : 2100 });
        companies[14] = Company({ capacity :  92, baseSalary : 4750 });
        companies[15] = Company({ capacity : 156, baseSalary : 2525 });
        companies[16] = Company({ capacity : 176, baseSalary : 2275 });
        companies[17] = Company({ capacity : 148, baseSalary : 3100 });
        companies[18] = Company({ capacity : 200, baseSalary : 2050 });
        companies[19] = Company({ capacity : 136, baseSalary : 3350 });
        companies[20] = Company({ capacity : 204, baseSalary : 2000 });
        companies[21] = Company({ capacity : 104, baseSalary : 4250 });
        companies[22] = Company({ capacity : 218, baseSalary : 1900 });
        companies[23] = Company({ capacity :  57, baseSalary : 6675 });
        companies[24] = Company({ capacity : 196, baseSalary : 2075 });
        companies[25] = Company({ capacity : 206, baseSalary : 2000 });
        companies[26] = Company({ capacity : 210, baseSalary : 1950 });
        companies[27] = Company({ capacity :  88, baseSalary : 4950 });
        companies[28] = Company({ capacity : 214, baseSalary : 1925 });
        companies[29] = Company({ capacity : 242, baseSalary : 1750 });
        companies[30] = Company({ capacity : 124, baseSalary : 3625 });
        companies[31] = Company({ capacity : 164, baseSalary : 2425 });
        companies[32] = Company({ capacity : 116, baseSalary : 3850 });
        companies[33] = Company({ capacity : 180, baseSalary : 2225 });
        companies[34] = Company({ capacity : 172, baseSalary : 2325 });
        companies[35] = Company({ capacity : 132, baseSalary : 3425 });
        companies[36] = Company({ capacity : 152, baseSalary : 3025 });
        companies[37] = Company({ capacity : 450, baseSalary : 1100 });
        companies[38] = Company({ capacity : 600, baseSalary : 900 });
        companies[39] = Company({ capacity : 112, baseSalary : 3975 });
        companies[40] = Company({ capacity :  65, baseSalary : 5900 });
        companies[41] = Company({ capacity :  76, baseSalary : 5500 });
        companies[42] = Company({ capacity :  80, baseSalary : 5400 });
        companies[43] = Company({ capacity :  84, baseSalary : 5150 });
        companies[44] = Company({ capacity : 290, baseSalary : 1500 });
        companies[45] = Company({ capacity : 108, baseSalary : 4100 });
        companies[46] = Company({ capacity : 276, baseSalary : 1575 });
        companies[47] = Company({ capacity : 400, baseSalary : 1200 });
        companies[48] = Company({ capacity :  53, baseSalary : 7150 });
        companies[49] = Company({ capacity : 300, baseSalary : 1475 });
        companies[50] = Company({ capacity :  69, baseSalary : 5875 });
        companies[51] = Company({ capacity :  72, baseSalary : 5650 });
        companies[52] = Company({ capacity : 208, baseSalary : 1975 });
        companies[53] = Company({ capacity : 128, baseSalary : 3525 });
        companies[54] = Company({ capacity :  73, baseSalary : 5575 });

// Specials companies

        // 55 Spooky
        _tempArray = [
            379, 391, 874, 1004, 1245, 1258, 1398, 1584, 1869, 1940, 1952, 2269, 2525, 2772, 3055, 3455, 3472, 3541, // 30 Clowns
            3544, 3607, 3617, 4103, 4117, 4149, 4195, 4230, 4425, 5065, 5101, 5188,
            4, 27, 48, 101, 136, 143, 157, 165, 172, 175, 226, 277, 388, 389, 418, 420, 444, 457, 493, 516, 518,  // 31 Heavy Makeup 
            610, 638, 679, 681, 703, 743, 784, 867, 917, 959
        ];
        parseSpecialRegIDs(55,_tempArray, 6250); 

        // 56 GM
        _tempArray = [
            4466, 4684, 5342, 5437, 5932, 6838, 8043, 1175, 1274, 2005, 2497, 2592, 3063, 3285, 3300, 3316,   // 32 Devils
            3454, 3983, 4541, 4856, 5171, 5219, 5265, 6643, 6719, 6982, 7147, 7303, 8012, 8944, 9644, 9822,
            1013, 1032, 1042, 1084, 1127, 1142, 1196, 1234, 1279, 1295, 1296, 1297, 1310, 1323, 1356, 1390, 1405  // 17 Heavy makeup
        ];
        parseSpecialRegIDs(56,_tempArray, 7700);

        // 57 McDanny's
        _tempArray = [
            1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663, 6762, 6831,  // McD's Workers + Managers
            7278, 7519, 8365, 9434, 64, 488, 642, 946, 1014, 1650, 1823, 1949, 2178, 2593, 2992, 3070, 3331, 3745, 
            3944, 3961, 4030, 4070, 4090, 4197, 4244, 4719, 5551, 5761, 5779, 5895, 6044, 6048, 6276, 6599, 6681, 
            6832, 6873, 6889, 7124, 7550, 7975, 8130, 8579, 8599, 8689, 8784, 8794, 8903, 9053, 9205, 9254, 9407, 9994
        ];
        parseSpecialRegIDs(57,_tempArray, 8250); 

        // 58 Wendy's
        _tempArray = [
            317, 456, 878, 1588, 2702, 2974, 3047, 3224, 3308, 3441, 4082, 4107, 5490, 5574, 5622, 6232, 6317,  // Wendys Workers
            6350, 6404, 6539, 7654, 7947, 7961, 8248, 8400, 8437, 8643, 8667, 8728, 9221, 9611, 9709, 9754, 9950
        ];
        parseSpecialRegIDs(58,_tempArray, 7900);

        // 59 Party Place - 25 Clowns + 26 heavy makeup
        _tempArray = [
            5494, 5845, 6016, 6042, 6073, 6109, 6436, 6649, 7092, 7574, 7863, 8077, 8110, 8326, 8359, 8480, 8629,  // 25 Clowns
            8825, 9303, 9319, 9339, 9770, 9800, 9858, 9870,
            1440, 1482, 1566, 1596, 1598, 1660, 1663, 1695, 1700,   // 26 heavy makeup
            1708, 1905, 1929, 1986, 2018, 2026, 2037, 2067, 2097, 2125, 2148, 2176, 2207, 2247, 2262, 2347, 2494
        ];
        parseSpecialRegIDs(59,_tempArray, 7425);

// McD's managers

        // These Ids are only used for seniority level bonus, on mint
        _tempArray = [1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663,  // 21 Managers
        6762, 6831, 7278, 7519, 8365, 9434 ]; 

        for (uint i = 0;i < _tempArray.length;i++){
            managerIds[_tempArray[i]] = true;
        }

//  
        specialCompanyIdFlag = 55;
        
        uint jobCountNotSpecial = 0;
        for (uint i = 0; i < specialCompanyIdFlag; i++) {
            jobCountNotSpecial += companies[i].capacity;
        }
        mainDeck.setup(jobCountNotSpecial);

        uint jobCountSpecial = 0;
        for (uint i = specialCompanyIdFlag; i < numCompanies(); i++) {
            jobCountSpecial += companies[i].capacity;
        }

        uint _startIndex = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            indexes[i] = uint16(_startIndex);
            _startIndex += companies[i].capacity;
        }
	}

// Admin Functions

    function makeNewJob(uint _regularId) public onlyRole(MINTER_ROLE) returns (uint, uint) {
        uint _pull;
        uint _specialCompanyId = specialCompanyIds[_regularId];
        uint _newJobId;
        if (_specialCompanyId == 0) {   
            // If Regular id is NOT special
            _pull = mainDeck.draw();
            uint _companyId = getCompanyId(_pull);
            counts[_companyId]++;
            emit jobIDCreated(_regularId, add1(_pull), _companyId, msg.sender);
            return (add1(_pull), _companyId);             
        } else {                        
            // If Regular id IS special
            _pull = specialDecks[_specialCompanyId].draw();
            _newJobId = _pull + indexes[_specialCompanyId];
            counts[_specialCompanyId]++;
            emit jobIDCreated(_regularId, add1(_newJobId), _specialCompanyId, msg.sender);
            return (add1(_newJobId), _specialCompanyId); 
        } 
    }

    function updateCompany(uint _companyId, uint128 _baseSalary, string memory _name) public onlyRole(MINTER_ROLE)  {
        companies[_companyId].baseSalary = _baseSalary;
        names[_companyId] = _name;
    } 

    function setSalaryMultiplier(uint _basispoints) public onlyRole(MINTER_ROLE) {
        SALARY_MULTIPLIER = _basispoints;
    }

// View Functions

    function getCount(uint _companyId) public view returns (uint) {
        return counts[_companyId];
    }

    function getBaseSalary(uint _companyId) public view returns (uint) {
        return companies[_companyId].baseSalary * SALARY_MULTIPLIER / 100;
    }

    function getSpread(uint _companyId) public pure returns (uint) {
        uint _nothing = 12345;
        return uint(keccak256(abi.encodePacked(_companyId + _nothing))) % 40;
    }

    function getCapacity(uint _companyId) public view returns (uint) {
        return companies[_companyId].capacity;
    }

    function numCompanies() public view returns (uint) {
        return companies.length;
    }

    function isManager(uint _regId) public view returns (bool) {
        return managerIds[_regId];
    }

    function maxJobIds() public view returns (uint) {
        uint _total = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            _total += companies[i].capacity;
        }
        return _total;
    }

    function getName(uint _companyId) public view returns (string memory) {
        return names[_companyId];
    }

// Internal

    function getCompanyId(uint _jobId) internal view returns (uint) {
        uint _numCompanies = companies.length;
        uint i;
        for (i = 0; i < _numCompanies -1; i++) {
            if (_jobId >= indexes[i] && _jobId < indexes[i+1])
                break;
        }
        return i;
    }

    function parseSpecialRegIDs(uint _companyId, uint[] memory _ids, uint _baseSalary) internal {
        for (uint i = 0;i < _ids.length; i++) {
            specialCompanyIds[_ids[i]] = _companyId;
        }
        companies[_companyId] = Company({ capacity : uint128(_ids.length), baseSalary : uint128(_baseSalary) }); 
        specialDecks[_companyId].setup(_ids.length);
    }

    function add1(uint _x) internal pure returns (uint) {
        return _x + 1;
    }

}