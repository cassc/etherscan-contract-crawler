//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MultisigOwnable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";
import "./BatchReveal.sol";

/*
:::::::::::::::::::::::::::::ヽヽヽヽ:::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::☆:::::::.:::::::::ヽヽヽヽヽ:::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::,'  ヽ.::::::::ヽヽヽ::::::::,.::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::。::/       ヽ:::::::::ヽヽ ::: ／   ヽ:::::::☆:::::::::::::☆::::::::☆::::::
::::::::::::::::::/           ヽ:::::::::☆::/         ヽ::::::::::::::::::::::::::::::::::::
::::::::::::::::;'              ｀--ｰｰｰｰｰ-く .         ',:::::::::::::::::::::::::::::::::
:::::::::☆:::::/                                       ',:::::::::::::::::::::::::::::::::
::::::::::::::/                                          ,:::::::::::::::::。:::::::::::::
:::::::::::::/                                            ,::::::::::::::。::::::::::::::::
::::::::::::;'                                            ::::::。:::::::::::::::::::::::::
:::。:::::: /                    , ＿＿＿＿＿＿             j::::::::::::::。::::::::::::::::
:::::::::: j               ' ´                   ｀ ヽ.      ,:::::::::::。::::::::::::::::::
::::::::::!              ´                           ヽ      ,:::::::::☆:::::::::::::::::::
::::::::: !             ´      ＿                ＿   ヽ     !::::::::::::::::::::::::::::::
::::::::: !            |  γ  =（   ヽ         : ' =::（ ヽ|     !:::::::::::::::::::::::::::::
::::::::: !            | 〈 ん:::☆:j j       ! ん:☆:::ﾊ       ::::::::::::::::::::::::::::::
::::::::: !            |  弋:::::.ﾉ ﾉ        ヾ:::::ﾉ ﾉ |     ::::::::::::::::::::::::::::::
:::::::::::'           |    ゝ  -  '     人    -    '  ﾉ     j::::::::::::::::::::::::::::::
:::::::::::,            ヽ                            ,     j::::☆::::::::::::::::::::::::::
::::::::::::,            ' ､                      , ／     ﾉ::::::::::::::::::::::::::::::::
::::::::::::::＼             ｰ--------------- '         ,':::::::::::::::::::::::::::::::::
::::☆:::::::::::ヽ                                    ／:::::::::::::::::::::::::::::::::::
:::::::::::::::::::7                :::::::::::::::＜::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::r´                   :::::::::::::ヽ::::::::::::::::::::::::::::::::::::
::::::::::::::::::/                               :::::ヽ::::::::::::::::::::::::::::::::::
*/

// IMPORTANT: _burn() must never be called
contract Tubbies is ERC721A, MultisigOwnable, VRFConsumerBase, BatchReveal {
    using Strings for uint256;

    bytes32 immutable public merkleRoot;
    uint immutable public startSaleTimestamp;
    string public baseURI;
    string public unrevealedURI;
    bool public finalized = false;
    bool public useFancyMath = true;
    bool public airdropped = false;

    // Constants from https://docs.chain.link/docs/vrf-contracts/
    bytes32 immutable private s_keyHash;
    address immutable private linkToken;
    address immutable private linkCoordinator;

    constructor(bytes32 _merkleRoot, string memory _baseURI, string memory _unrevealedURI, bytes32 _s_keyHash, address _linkToken, address _linkCoordinator)
        ERC721A("Tubby Cats", "TUBBY")
        VRFConsumerBase(_linkCoordinator, _linkToken)
    {
        linkToken = _linkToken;
        linkCoordinator = _linkCoordinator;
        s_keyHash = _s_keyHash;
        merkleRoot = _merkleRoot;
        startSaleTimestamp = block.timestamp + 2 days;
        unrevealedURI = _unrevealedURI;
        baseURI = _baseURI;
    }

    function airdrop(address[] memory airdrops) external onlyRealOwner{
        require(airdropped == false, "already airdropped");
        for(uint i=0; i<airdrops.length; i++){
            _mint(airdrops[i], 1, '', false);
        }
        airdropped = true;
    }

    function setParams(string memory newBaseURI, string memory newUnrevealedURI, bool newFinal, bool newUseFancyMath) external onlyRealOwner {
        require(finalized == false, "final");
        baseURI = newBaseURI;
        unrevealedURI = newUnrevealedURI;
        finalized = newFinal;
        useFancyMath = newUseFancyMath;
    }

    function retrieveFunds(address payable to) external onlyRealOwner {
        to.transfer(address(this).balance);
    }

    // SALE

    function toBytes32(address addr) pure internal returns (bytes32){
        return bytes32(uint256(uint160(addr)));
    }

    // CAUTION: Never introduce any kind of batch processing for mint() or mintFromSale() since then people can
    // execute the same bug that appeared on sushi's bitDAO auction
    // There are some issues with merkle trees such as pre-image attacks or possibly duplicated leaves on
    // unbalanced trees, but here we protect against them by checking against msg.sender and only allowing each account to claim once
    // See https://github.com/miguelmota/merkletreejs#notes for more info
    mapping(address=>bool) public claimed;
    function mint(bytes32[] calldata _merkleProof) public payable {
        require(MerkleProof.verify(_merkleProof, merkleRoot, toBytes32(msg.sender)) == true, "wrong merkle proof");
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;
        require(msg.value == 0.1 ether, "wrong payment");
        _mint(msg.sender, 1, '', false);
        require(totalSupply() <= TOKEN_LIMIT, "limit reached");
    }

    function mintFromSale(uint tubbiesToMint) public payable {
        require(block.timestamp > startSaleTimestamp, "Public sale hasn't started yet");
        require(tubbiesToMint <= 5, "Only up to 5 tubbies can be minted at once");
        uint cost;
        unchecked {
            cost = tubbiesToMint * 0.1 ether;
        }
        require(msg.value == cost, "wrong payment");
        _mint(msg.sender, tubbiesToMint, '', false);
        require(totalSupply() <= TOKEN_LIMIT, "limit reached");
    }

    // RANDOMIZATION

    uint public lastTokenRevealed = 0;
    // Can be made callable by everyone but restricting to onlyRealOwner for extra security
    // batchNumber belongs to [0, TOKEN_LIMIT/REVEAL_BATCH_SIZE]
    // if fee is incorrect chainlink's coordinator will just revert the tx so it's good
    function requestRandomSeed(uint s_fee) public onlyRealOwner returns (bytes32 requestId) {
        require(totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE), "totalSupply too low");

        // checking LINK balance
        require(IERC20(linkToken).balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");

        // requesting randomness
        requestId = requestRandomness(s_keyHash, s_fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE), "totalSupply too low");
        uint batchNumber = lastTokenRevealed/REVEAL_BATCH_SIZE;
        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        batchToSeed[batchNumber] = randomness % (TOKEN_LIMIT - (batchNumber*REVEAL_BATCH_SIZE));
        unchecked {
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
    }

    // OPTIMIZATION: No need for numbers to be readable, so this could be optimized
    // but gas cost here doesn't matter so we go for the standard approach
    function tokenURI(uint256 id) public view override returns (string memory) {
        if(!useFancyMath){
            return string(abi.encodePacked(baseURI, id.toString()));
        }
        if(id >= lastTokenRevealed){
            return unrevealedURI;
        } else {
            uint batch = id/REVEAL_BATCH_SIZE;
            return string(abi.encodePacked(baseURI, getShuffledTokenId(id, batch).toString(), ".json"));
        }
    }
}