//SPDX-License-Identifier: MIT

/*

 ____                     __               __          ______    __              ______           __                
/\  _`\                  /\ \__         __/\ \        /\__  _\__/\ \      __    /\__  _\       __/\ \               
\ \ \L\ \     __     __  \ \ ,_\   ___ /\_\ \ \/'\    \/_/\ \/\_\ \ \/'\ /\_\   \/_/\ \/ _ __ /\_\ \ \____     __   
 \ \  _ <'  /'__`\ /'__`\ \ \ \/ /' _ `\/\ \ \ , <       \ \ \/\ \ \ , < \/\ \     \ \ \/\`'__\/\ \ \ '__`\  /'__`\ 
  \ \ \L\ \/\  __//\ \L\.\_\ \ \_/\ \/\ \ \ \ \ \\`\      \ \ \ \ \ \ \\`\\ \ \     \ \ \ \ \/ \ \ \ \ \L\ \/\  __/ 
   \ \____/\ \____\ \__/.\_\\ \__\ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\  \ \_\ \_,__/\ \____\
    \/___/  \/____/\/__/\/_/ \/__/\/_/\/_/\/_/\/_/\/_/      \/_/\/_/\/_/\/_/\/_/      \/_/\/_/   \/_/\/___/  \/____/
                                                                                                                                                                                                                                        
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract HC {
    function mint(address to, uint256 amount) public virtual;
}

contract HulaDistributor is Pausable, AccessControlEnumerable {

    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    uint public constant START_DATE = 1635724800; // Mon, 1 Nov 2021 0:00:00 GMT
    uint public constant END_DATE = 1951257600; // Mon, 1 Nov 2031 0:00:00 GMT

    uint public UNIKI_DAILY_YIELD = 30 ether;
    uint public SPECIAL_DAILY_YIELD = 6 ether;
    uint public REGULAR_DAILY_YIELD = 5 ether;

    mapping(uint => bool) private unikis;
    mapping(uint => bool) private specials;
    mapping(uint => uint) public outstandingBalance;
    mapping(uint => uint) public claimDate;

    IERC721Enumerable bttContract;
    HC hulaContract;

    constructor(address _bttAddress, address _hulaAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REWARDER_ROLE, _msgSender());

        bttContract = IERC721Enumerable(_bttAddress);
        hulaContract = HC(_hulaAddress);

        uint[10] memory unikiIds = [ uint(1353), 1960, 1996, 2092, 2147, 3022, 3033, 3577, 4010, 4632 ];
        for (uint i=0; i<unikiIds.length; i++)
            unikis[unikiIds[i]] = true;
        

        uint[12] memory specialIds = [ uint(14), 694, 805, 2278, 2382, 2739, 2748, 2980, 4220, 4337, 4613, 4842 ];
        for (uint i=0; i<specialIds.length; i++)
            specials[specialIds[i]] = true;
    }

    function containsAll(uint[] memory _tokenids, uint[] memory _ownerTokenIds) private pure returns (bool) {

        for (uint i=0; i<_tokenids.length; i++) {

            bool contained = false;
            uint tokenid = _tokenids[i];

            for (uint j=0; j<_ownerTokenIds.length; j++) {
                if (tokenid == _ownerTokenIds[j]) {
                    contained = true;
                    break;
                } 
            }

            if (!contained) {
                return contained;
            }
        }

        return true;
    }

    function isTokenOwner(address _address, uint[] memory _tokenids) private view returns (bool) {
        uint balance = bttContract.balanceOf(_address);
        uint[] memory ownerTokenIds = new uint[](balance);

        for (uint i=0; i<balance; i++) {
            ownerTokenIds[i] = bttContract.tokenOfOwnerByIndex(_address, i);
        }

        bool isOwner = containsAll(_tokenids, ownerTokenIds);

        return isOwner;
    }
    function availableHula(uint[] memory _tokenids) public view returns (uint[] memory) {
        
        uint[] memory available = new uint[](_tokenids.length);

        for (uint i=0; i<_tokenids.length; i++) {

            uint _tokenid = _tokenids[i];
            uint startDate = (claimDate[_tokenid] > 0) ? claimDate[_tokenid] : START_DATE;
            uint numOfDays = (block.timestamp - startDate) / (1 days);
            uint _available;

            if (unikis[_tokenid])
                _available = numOfDays * UNIKI_DAILY_YIELD;
            else if (specials[_tokenid])
                _available = numOfDays * SPECIAL_DAILY_YIELD;
            else
                _available = numOfDays * REGULAR_DAILY_YIELD;

            _available += outstandingBalance[_tokenid];
            available[i] = _available;
        }

        return available;
    }

    function claimHula(uint _tokenid, uint _amount) public whenNotPaused {
        address sender = _msgSender();
        
        uint[] memory _tokenids = new uint[](1);
        _tokenids[0] = _tokenid;
        require(isTokenOwner(sender, _tokenids), 'HulaDist: Must own tiki to claim hula');
        
        uint available = availableHula(_tokenids)[0];
        require(_amount <= available, 'HulaDist: Cannot claim more than available balance');

        claimDate[_tokenid] = block.timestamp;
        outstandingBalance[_tokenid] = available - _amount;
        hulaContract.mint(sender, _amount);
    }

    function claimAllHula(uint[] calldata _tokenids) external whenNotPaused {
        
        address sender = _msgSender();
        require(isTokenOwner(sender, _tokenids), "HulaDist: Must own all tikis to claim all hula");
        
        uint[] memory available = availableHula(_tokenids);

        uint total = 0;
        for (uint i=0; i<_tokenids.length; i++) {
            claimDate[_tokenids[i]] = block.timestamp;
            outstandingBalance[_tokenids[i]] = 0;
            total += available[i];
        }

        hulaContract.mint(sender, total);
    }

    function addBalance(uint _tokenid, uint _amount) public {
        require(hasRole(REWARDER_ROLE, _msgSender()), "HulaDist: Must have rewarder role");
        outstandingBalance[_tokenid] += _amount;
    }

    function removeBalance(uint _tokenid, uint _amount) public {
        require(hasRole(REWARDER_ROLE, _msgSender()), "HulaDist: Must have rewarder role");
        require(_amount <= outstandingBalance[_tokenid], "HulaDist: Cannot remove more than available");
        outstandingBalance[_tokenid] -= _amount;
    }

    function mintHula(address _address, uint _amount) public {
        require(hasRole(REWARDER_ROLE, _msgSender()), "HulaDist: Must have rewarder role");
        hulaContract.mint(_address, _amount);
    }

    function setDailyYield(uint _regular, uint _special, uint _uniki) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HulaDist: Must have admin role");
        REGULAR_DAILY_YIELD = _regular;
        SPECIAL_DAILY_YIELD = _special;
        UNIKI_DAILY_YIELD = _uniki;
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HulaDist: Must have admin role");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "HulaDist: Must have admin role");
        _unpause();
    }

}