// SPDX-License-Identifier: MIT

/*
  _________         .___     _________ .__                                
 /   _____/__ __  __| _/____ \_   ___ \|  |__ _____    ____   ____  ____  
 \_____  \|  |  \/ __ |/  _ \/    \  \/|  |  \\__  \  /    \_/ ___\/ __ \ 
 /        \  |  / /_/ (  <_> )     \___|   Y  \/ __ \|   |  \  \__\  ___/ 
/_______  /____/\____ |\____/ \______  /___|  (____  /___|  /\___  >___  >
        \/           \/              \/     \/     \/     \/     \/    \/ 

    Official Twitter: https://twitter.com/sudoswapgame
    Coded by: https://twitter.com/HakoCode
*/

pragma solidity 0.8.16;

import "./ERC721A/IERC721A.sol";
import "./ERC721A/ERC721A.sol";
import "./SudoSwap/ILSSVMPairFactory.sol";
import "./SudoSwap/ILSSVMPair.sol";
import "./SudoSwap/ICurve.sol";
import {SafeTransferLib} from "./Solmate/SafeTransferLib.sol";

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract SudoChance is ERC721A, RrpRequesterV0 {
    using SafeTransferLib for address payable;

    ILSSVMPairFactory private constant SUDO_PAIR_FACTORY = ILSSVMPairFactory(0xb16c1342E617A5B6E4b631EB114483FDB289c0A4);
    ICurve constant private SUDO_EXP_CURVE = ICurve(0x432f962D8209781da23fB37b6B59ee15dE7d9841);

    address constant private API3_AIRNODE_RRP_ADDRESS = 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
    address constant private API3_AIRNODE_ADDRESS = 0x9d3C147cA16DB954873A498e0af5852AB39139f2;
    bytes32 constant private API3_UINT256_ENDPOINT_ID = 0xfb6d017bb87991b7495f563db3c8cf59ff87b09781947bb1e417006ad7f55a78;

    uint256 constant public MAX_SUPPLY = 2500;
    uint128 constant public STARTING_PRICE = 0.002 ether;
    uint128 constant public EXP_DELTA = 1001500000000000000;

    GameState public currentState;
    ILSSVMPair public gameSudoPool;
    uint256 public numberOfTicketSold;
    bytes32 private lastRandomnessRequestId;
    uint256 private lastRandomNumber;
    address private teamWallet;
    address private sponsorWallet;

    enum GameState {
        CREATED,
        ACTIVE,
        PRIZE,
        ENDED
    }

    event RequestedUint256(bytes32 indexed requestId);
    event ReceivedUint256(bytes32 indexed requestId, uint256 response);


    constructor() ERC721A("SudoChance Genesis", "SCG") RrpRequesterV0(API3_AIRNODE_RRP_ADDRESS) {
        currentState = GameState.CREATED;
        teamWallet = _msgSenderERC721A();
    }

    receive() external payable {}
    fallback() external payable {}

    function intializeGame(address _sponsorWallet) external onlyTeam {
        require(currentState == GameState.CREATED, "Game already active");
        sponsorWallet = _sponsorWallet;

        setupSudoPool();
        _mintERC2309(address(gameSudoPool), MAX_SUPPLY);
        currentState = GameState.ACTIVE;
    }

    function setupSudoPool() internal {
        gameSudoPool = SUDO_PAIR_FACTORY.createPairETH(
            IERC721A(this),
            SUDO_EXP_CURVE,
            payable(0),
            ILSSVMPair.PoolType.TRADE,
            EXP_DELTA,
            0,
            STARTING_PRICE,
            new uint256[](0)
        );
    }

    function getBurnCount() view public returns (uint256) {
        return _totalBurned();
    }

    function distributePrize() external onlyTeam {
        require(currentState == GameState.PRIZE, "Game not in prize phase");
        (,address winner) = getRandomGameWinner();
        gameSudoPool.withdrawAllETH();

        payable(teamWallet).safeTransferETH(address(this).balance / 10);
        payable(winner).safeTransferETH(address(this).balance);

        currentState = GameState.ENDED;
    }

    function getRandomGameWinner() public view returns (uint256, address)  {
        require(lastRandomNumber != 0, "Randomness not initialized");
        uint256 entropy = lastRandomNumber;
        uint256 winningTicketId;

        for (uint i = 0; i < 10; i++) {
            (winningTicketId, entropy) = getNextRandom(MAX_SUPPLY, entropy, 25);
            address ticketOwner = ownerOf(winningTicketId);

            if (ticketOwner != address(0) && ticketOwner != address(gameSudoPool))
            {
                return (winningTicketId, ticketOwner);
            }
        }
        revert("No winner found");
    }

    function getNextRandom(uint256 maxNumber, uint256 entropy, uint256 bits) private pure returns (uint256, uint256) {
        uint256 maxB = (uint256(1)<<bits);
        if (entropy < maxB) entropy = uint256(keccak256(abi.encode(entropy)));
        uint256 rnd = (entropy & (maxB - 1)) % maxNumber;
        return (rnd, entropy >> bits);
    }

    function makeRequestUint256(bool test) external onlyTeam {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            API3_AIRNODE_ADDRESS,
            API3_UINT256_ENDPOINT_ID,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillUint256.selector,
            ""
        );
        emit RequestedUint256(requestId);
        
        if (!test)
            lastRandomnessRequestId = requestId;
    }

    function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp
    {
        require(lastRandomnessRequestId == requestId, "Invalid id");
        lastRandomNumber = abi.decode(data, (uint256));
        lastRandomnessRequestId = 0x0;

        emit ReceivedUint256(requestId, lastRandomNumber);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        require(currentState == GameState.ACTIVE || currentState == GameState.CREATED, "Game must be active");
        
        if (to == address(0) && from != address(gameSudoPool))
            revert("Can't burn directly");
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        if (to == address(gameSudoPool) && from != address(0)) {
            for (uint i = 0; i < quantity; i++)
                _burn(startTokenId + i);
        }
        else if (from == address(gameSudoPool) && to != address(0)) {
            uint256 currentTicketSold = numberOfTicketSold;
            unchecked {
                currentTicketSold++;
            }
            numberOfTicketSold = currentTicketSold;

            if (numberOfTicketSold >= MAX_SUPPLY)
                currentState = GameState.PRIZE;
        }
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        uint256 realBalance = super.balanceOf(owner);

        if (owner == address(gameSudoPool) && msg.sender != tx.origin)
            return realBalance + getBurnCount();
        else
            return realBalance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        TokenOwnership memory ownership = explicitOwnershipOf(tokenId);

        if (ownership.burned && msg.sender != tx.origin)
            return address(gameSudoPool);
        else
            return ownership.addr;
    }

    function explicitOwnershipOf(uint256 tokenId) public view virtual returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = super.balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;

            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds[index];
        }
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory base = "data:application/json;base64,";
        string memory tokenID = Strings.toString(tokenId);
        string memory json = string(abi.encodePacked(
            '{\n\t"name": "SC Ticket #', tokenID,
            '",\n\t"description": "', "SudoChance is an innovative game on SudoSwap where the winner gets all of the liquidity in the pool",
            '",\n\t"image": "', "ipfs://Qmczti8PU1uumZt6kV4FXSE1pL7gABVFfVpRaHsLqFxTpm",
            '"\n}'));

        return string(abi.encodePacked(base, Base64.encode(bytes(json))));
    }

    modifier onlyTeam() {
        require(msg.sender == teamWallet, "Not allowed");
        _;
    }
}