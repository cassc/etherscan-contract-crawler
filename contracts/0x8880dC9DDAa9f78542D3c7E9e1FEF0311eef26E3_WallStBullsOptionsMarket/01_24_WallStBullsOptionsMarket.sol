// SPDX-License-Identifier: MIT

/****
 _       __      ____   _____ __     ____        ____
| |     / /___ _/ / /  / ___// /_   / __ )__  __/ / /____
| | /| / / __ `/ / /   \__ \/ __/  / __  / / / / / / ___/
| |/ |/ / /_/ / / /   ___/ / /_   / /_/ / /_/ / / (__  )
|__/|__/\__,_/_/_/   /____/\__/  /_____/\__,_/_/_/____/
         ____        __  _                     __  ___           __        __
        / __ \____  / /_(_)___  ____  _____   /  |/  /___ ______/ /_____  / /_
       / / / / __ \/ __/ / __ \/ __ \/ ___/  / /|_/ / __ `/ ___/ //_/ _ \/ __/
      / /_/ / /_/ / /_/ / /_/ / / / (__  )  / /  / / /_/ / /  / ,< /  __/ /_
      \____/ .___/\__/_/\____/_/ /_/____/  /_/  /_/\__,_/_/  /_/|_|\___/\__/
          /_/
... .....';cc;........... ...........''''''.......'''','.....;ll:'.....','.....'''';ll,'co:,cl;'',cl:,,;;;;,,,,,,,,;;;:::cccccccccccc
'.... .....';,....................'''........',,.,:::;,,....'cooolc:'...,,......'''':ll:lc,'::;''',,,,,,,,,;;;::::cccccccc:::::::::::
''''.. .................................,;;',::;,;c,,c;,'...,loooollc,..','.......''',;;,'''''''',,,;;:::::::::::::;;;;;:::::::::::::
...','. ...........''.............''...'::,',:;;;;c:':c;,...,:;;,,,'.....,,............'',,,;;;;;::::::;;;;;;;;;;;;;;::::::::::::::::
,...... ......................;,.'::'...,:;;;:c;;ccc,'c:,'................,'...''',,,;;;;;;;;;;;,,,,,,;;;;;;;:::;:cldxxdoc;;;::::::::
................ .. ..........;:,..;:'...,'':::;'::;:::;'''.............'';;,,,,;;;;,,,,,,,,,,,,,,,,;::;;;:loodddxO0K0Oxdo:;;;;;:::::
............... ..'............';'..;;..',,;::',;;,.'''..''....'''''',,,,,,;,'''''''',,,,;::,,,,,,;:odl;;cdxxkO000KXXKOxoc;;;;;;:::::
............... .,c;'...........,;'..;,.,'',,........''''',,''''''''''..''',,'''''''''';olloo:,,,,coodddxk0KKKKKK00KXK0xooc;;;;;;;:::
...',,,,'........'c:;'...........''..........'.'...........''.......''..'''',,'''''''''cdc,:do;,;lodkO00OO0XK0O0KKKKK0Ododl:;;;;;;;;:
,'.',;;,'','................................................''.....':c;''''',,''''''''':do,,ld:;:oxkk0K0kkOKKOO0KK00KK0xooc;;;;;;;;;:
','..,,'.'','.......  ............................','..;;,'..'.....,lllc;'..',,'''''''',ld:'cdc,:c:cldkkkkkO00000OkkOOOxl:;;;;;;;;;;:
.',,'.''................................'....';,,,;;,;,;,,,..''..',:lllll:,'.','.''''''';loclo:,cl;,,:ldxxxxkkkkkkkkkkkxl::::::cc:::c
..............................     .....;;......;,.;;;;;c,,:'.'..',;;;;,,,'..',,.'''''''',;:;,''',,,;coxxxxxkkkkkkkkkkkkoc::::::;;;;;
................ .......,'.....    ......,,.....;'.,;.;:;;':;..'..............','...''''',,,,,,,,;;:cdxxxxxxxxxxdxxxxxxko;,,,,,,,,,,,
............'....  ....'::;'....      ....,'..',;,'''','..''...''........''''',,,'''''''','''''''';lddddddddddoc;:codxxkd:;,,,,,,,,,,
....'...'..',''.........;;;,.....   .  ........................','.............','..............';lddddxxxxxdolcccc;:oddooo:,,,,,,,,,
.....'......'...'''.............................................'...............''.....;,......':okxddkkxxxdloo:,:c,,::;;ldc,',,,,,,,
......'......................................................'''.''.........''...'...':oo'....':oxkkddkkxdoc:odc:clc,.',cloc,'''',,,,
..............................................''...',,,';;;,,:;,'''....;cccll;.........;o:...,:oxdxkxddxdlloccdl',ld:,;,';odc''''''',
.............................................',,;'.''.;;,;;:;::,;,''....':ll:.....'....'ll'.,codxxxkkxdol;cdc;lo:;lo:;ll:cll;''''''',
.. ..........''.''','........,:c,..............';....':'.;;,;::,,::,'.....';'...........;l:;cddoooodxdl:::::'.';:;;,'.',;;,''''''''''
....'.....''..''''''''''.......;'. ............,;,''',;,,,,,;,',,,;'...............'.....,:clllllooolc,'....'''''''',,,,,,,,,,;;;;;;;
. .........'...',''...'''..... ... .............''...................'.............',..',:looooooool:;,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;
. ....................................................................''............''',:cllllllll:;'..'.'''''''''''''',,,,,,,,,,,,,,
...........................................  ...  ....   ...........................',,:clloolllc:;:;;;',::;::,,:c:::;;:ccccl:,,,,,,,
............................ ............   ..''...,''...',..,,'.':;,'........,'....';:clloxdlc:,,:l,,cc;:;':o:;ll;:lc,,,,:ll;,,,,,,,
''''......'.....'..................';,.......;::;'.,.''...',..'',;;;,','.....,cc;'..;clccclodl;,..;l;';l;.';cc,':l::lc,'';ll;',,,,,,,
.'.'.............'..........'......';;,....';:::::;,,',....,'..',;,,,';,....':cccc;;ccllcccll:'.',,:c,;l;,cl:,,,cl;,:oc',co:'''',,,,,
..........................................;:::::::::;,........................''',:cccclccc:,,..','',;;;'';;;;;,,;;;::,',::,'''''',,,
........................................';:cc:::;;ccc:;'..................'.....,:cccclllc;'......''''''''''''''''''''''''',,,,,,,,,,
..'''''... .....;;,'''..'''''''.........;:::::;...';::::,......................,:ccccccc:'.......................'''''''''''''',,,,,,
..;:;,..... ...'::::;,'..''',,'''.....':llc::,......';::::,.';,,,...,..;;'....,:cclccc:;'..........'''.......''......................
...;::;'.......'::::c:;'....''...'...':ccll:'.........';:::;,,;,;,.',..;;;'.';:ccoxdl:'...........,,',:'...';,,:;...;c:'...;c:,......
...':ccc:;'....,:::;;::;,............,cc::;.............,;::::;,',,,,..;;,;;:c:clddoc;'.............';;.......,::..;;:c,..;::l;......
....,cc;;:c:;'.,:::,..,:c:,..........,:cc:'...............,;ccc:,'........,:clc:cc:,...............,c;'...'.',.,c;;:;;l:,:c;:lc'.....
.....,::,',;c:;::::'...',:cc,,'..''.';::c;'',,'...     .....,:c::;;,.....,:ccclcc:,...................''..'..''','...';;'''',cc,.....
......;c;'..',::::;.......,:c:;'....':c::;..';,....    ..'. .';cc::c:'.';:::cccc;'.........'.........................................
......':c;'...',;:,.........,::;,...':cc:,..........    ..'....,;:llolc:clclol:,...,,,,,'.......'''................''''''''''''''''''
;'.....,::,..................';:cc;',:cc:'.....................'.',;clllcllll:,'....,:c:'......':,,;'...';;'..,,,,'..',''.....'''''''
,;:;''..,::'..................',;ccccccc;.....  ....................';:cccc:,'........,'........:,.;;....,:;.',''::,:c,;:,..,:c;'...'
..';:;,'';:;'....................',:ccc:;''.....';'...................,;::;'....................',';;.''..;:'..,:;,':c''cc,;::cc'...'
 ....,;:;,:c;......'''..............';::'.........'............',',...'';;,'..................'.......''..',..';;,,',:;,:c;;;;cl;'..'
.......';:cc:,.......................';;........................'',,...','.','';;....  ...........................''.'',,'....,:,....
..........,:::'.......................'..'..........'.............'....''...,,,,,,'.. .,:;'.. .....'...........................''''.'
............,;,.....................................,;'...     ..................'.....',,,'......';.';....';,..''.'.................
..............'............................................             ...........................,'';'....,;..;;';:,;;',,.','''....
.........................................'''''................          .',''.....'..........................,...,,,:;:;.'c;...,c;...
............................................'..''...........................'''..';'.....',,''......................'..,'';'.;:;,....
........................................................,,..........................'.....';:;........,'.....................''''....
****/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./ChainlinkVRF.sol";

contract WallStBullsOptionsMarket is ERC721Holder, ChainlinkVRF {
    enum State{FREE, BALLER, HOMELESS, PRISON, DEAD, IN_PROGRESS}
    struct TokenState {
        address owner;
        State state;
        uint32 order;
    }

    uint256 public constant PRICE = 1;
    uint256 public constant MAX_ROLL = 100;

    address public prisonWallet;
    address public constant graveyardWallet = 0xdeAD42069DEaD42069deAD42069Dead42069DeAd;

    uint256 private deadUpperBound;
    uint256 private prisonUpperBound;
    uint256 private ballerUpperBound;

    bool public saleActive;

    ERC1155Burnable public erc1155;
    uint256 public erc1155TokenId = 0;
    ERC721Enumerable public erc721;

    mapping(uint256 => TokenState) private states;
    event TokenStateChange(uint256 tokenId, State state, uint32 order);

    constructor(
        address _erc1155Address,
        uint256 _erc1155TokenId,
        address _erc721Address,
        address _prisonWallet,
        uint256 _ballerOdds,
        uint256 _homelessOdds,
        uint256 _prisonOdds,
        uint256 _deadOdds,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) ChainlinkVRF(_vrfCoordinator, _subscriptionId, _keyHash) {
        erc1155 = ERC1155Burnable(_erc1155Address);
        erc1155TokenId = _erc1155TokenId;
        erc721 = ERC721Enumerable(_erc721Address);
        prisonWallet = _prisonWallet;
        _setOdds(_ballerOdds, _homelessOdds, _prisonOdds, _deadOdds);
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setPrisonWallet(address _prisonWallet) external onlyOwner {
        prisonWallet = _prisonWallet;
    }

    function odds() external view returns (uint256 ballerOdds, uint256 homelessOdds, uint256 prisonOdds, uint256 deadOdds) {
        return (
            ballerUpperBound - prisonUpperBound,
            MAX_ROLL - ballerUpperBound,
            prisonUpperBound - deadUpperBound,
            deadUpperBound
        );
    }

    function _setOdds(uint256 _ballerOdds, uint256 _homelessOdds, uint256 _prisonOdds,  uint256 _deadOdds) internal {
        require(_ballerOdds + _homelessOdds + _prisonOdds + _deadOdds == MAX_ROLL, "Sum of odds must be 100%");
        ballerUpperBound = _deadOdds + _prisonOdds + _ballerOdds;
        prisonUpperBound = _deadOdds + _prisonOdds;
        deadUpperBound = _deadOdds;
    }

    function setOdds(uint256 _ballerOdds, uint256 _homelessOdds, uint256 _prisonOdds,  uint256 _deadOdds) external onlyOwner {
        _setOdds(_ballerOdds, _homelessOdds, _prisonOdds, _deadOdds);
    }

    function initializeTokenState(uint256 _tokenId, address _owner, State _state, uint32 _order) external onlyOwner {
        states[_tokenIdToIndex(_tokenId)] = TokenState(_owner, _state, _order);
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        (bool success,) = _to.call{value : _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function getTokenState(uint256 _tokenId) external view onlyOwner returns (TokenState memory) {
        return _getTokenState(_tokenId);
    }

    function _getTokenState(uint256 _tokenId) internal view returns (TokenState memory) {
        return states[_tokenIdToIndex(_tokenId)];
    }

    function _setTokenState(uint256 _tokenId, TokenState memory _tokenState, State _state) internal {
        states[_tokenIdToIndex(_tokenId)] = TokenState(_tokenState.owner, _state, _tokenState.order + 1);
        emit TokenStateChange(_tokenId, _state, _tokenState.order + 1);
    }

    function option(uint256 _tokenId) external returns (uint256 requestId) {
        require(saleActive, "Sale is not active");
        TokenState memory token = _getTokenState(_tokenId);

        erc1155.burn(msg.sender, erc1155TokenId, PRICE);
        erc721.transferFrom(msg.sender, address(this), _tokenId);

        requestId = _requestRandomWords();
        states[_tokenIdToIndex(_tokenId)] = TokenState(msg.sender, State.IN_PROGRESS, token.order);
        _setRequestStatus(requestId, _tokenId);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 tokenId = _getRequestStatus(_requestId);
        TokenState memory token = _getTokenState(tokenId);

        State state = _rollToState(_randomWords[0] % 100);
        if (state == State.DEAD) {
            erc721.transferFrom(address(this), graveyardWallet, tokenId);
        } else if (state == State.PRISON) {
            erc721.transferFrom(address(this), prisonWallet, tokenId);
        } else {
            erc721.transferFrom(address(this), token.owner, tokenId);
        }
        _setTokenState(tokenId, token, state);
    }

    function release(uint256 _tokenId) external {
        require(saleActive, "Sale is not active");
        TokenState memory token = _getTokenState(_tokenId);
        require(token.state == State.PRISON, "Token is not in prison");
        require(token.owner == msg.sender, "Address is not token owner");

        erc1155.safeTransferFrom(msg.sender, prisonWallet, erc1155TokenId, PRICE, "");
        erc721.transferFrom(prisonWallet, msg.sender, _tokenId);

        _setTokenState(_tokenId, token, State.FREE);
    }

    function unstuck(uint256 _tokenId) external onlyOwner {
        erc721.transferFrom(address(this), _getTokenState(_tokenId).owner, _tokenId);
    }

    function _rollToState(uint256 roll) internal view returns (State) {
        if (roll < deadUpperBound) {
            return State.DEAD;
        } else if (roll < prisonUpperBound) {
            return State.PRISON;
        } else if (roll < ballerUpperBound) {
            return State.BALLER;
        }
        return State.HOMELESS;
    }

    function _tokenIdToIndex(uint256 _tokenId) internal pure returns (uint256) {
        return _tokenId - 1;
    }
}