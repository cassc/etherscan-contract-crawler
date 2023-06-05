// SPDX-License-Identifier: MIT
// Some gas saving tips and tricks for our allow-list approach were taken
// from a very well written and thought-out article by nftchance, go check it out!
// https://nftchance.medium.com/the-gas-efficient-way-of-building-and-launching-an-erc721-nft-project-for-2022-b3b1dac5f2e1
//
// GM
// Collection and good vibes by https://twitter.com/zaingaziani/
// Contract by austink.eth
// Website by https://twitter.com/k_optional and austink.eth
//
//
//                   (       )                        (       (  (               (   (
//                   )\   ( /( (                 (    )\      )\))(   '     (    )\  )\ )
//                 (((_)  )\()))\  `  )   `  )   )\ )((_)(   ((_)()\ )  (   )(  ((_)(()/(
//                 )\___ ((_)\((_) /(/(   /(/(  (()/(    )\  _(())\_)() )\ (()\  _   ((_))
//                ((/ __|| |(_)(_)((_)_\ ((_)_\  )(_))  ((_) \ \((_)/ /((_) ((_)| |  _| |
//                 | (__ | ' \ | || '_ \)| '_ \)| || |  (_-<  \ \/\/ // _ \| '_|| |/ _` |
//                  \___||_||_||_|| .__/ | .__/  \_, |  /__/   \_/\_/ \___/|_|  |_|\__,_|
//                                |_|    |_|     |__/
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0OXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;..,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl....lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,....,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo......oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;.''''.,0MMMMMMMMMMMMMMNO0WMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMMMMMMMMMMMMMMx........lNMMMMMMMMMMMMMk.,0MMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMXc:KMMMMMMMMMMMMMXc.''''''.'kMMMMMMMMMMMMK:..dMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMx..dWMMMMMMMMMMMMk..........cXMMMMMMMMMMXc...oMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMd...xWMMMMMMMMMMX:.''''''''..l0WMMMMMMW0:....dMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMO'..'lKMMMMMMMNx:...'''''.....':xNMMMXd'....'kMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMNc.'..,okXWMW0:.''.........',,,'':dko,..''..;KMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMk'..''..,:c:'.',,,,,'',,,,,,,,,''...'...'.'kMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.''...''...,'''',,,,,,,,,''...''..','..,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc....','..''...',,,,,,,,,''''..''..''.;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'..,,..''...,,,,,,,,,,,,,,,,'','..'oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdc;'..','.'',,',,,,,,,,'''',,,,.,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0:.',,,,',;,',',,,,'.:o,',,,.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.',,,,.:Oc.,,,,,,'.:d;.,,'.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.,,,,',;,',,,,,',''.'',,.;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.',,,,,,,,,''''...'',,,''dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.,,,,,,,'.'......',,,'.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMWk'.,,,,,,'..,,;;..,,,'.lXMMXkloKMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl;cd0NWO;.',,,,'...;c,.','.,xNWKd,...xMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc....:oxxc'.',,'','''.',''cOKkl,....,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,...''.,:,...'',,,,,''..;lc,.'',''.oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.',,,,,'''.............'',,,,,'.lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc'',,,,,',,,'''''''',,,,,,,,,'.lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;.',,,,,,,,,,,,,,,,,,,,,,,''oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;.',,,,,,,,,,,,,,,,,,,'.,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc'.',,,,,,,,,,,,,,'..:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.',,,,,,,,,,,,,,..lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl.',,,,,,,,,,,,,,''xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOkNMMMMMNc.,,,,,,,,,,,,,,,'.lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:.dNMMMMK:.,,,,,,,,,,,,,,,,.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc.'lKMMMK;.,',,,,,,,,,,,,,,'.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk'..,oON0,.,',,,,,,,,,,,,,,,.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'''.';;..,,,,,,,,,,,,,,,,,.;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,...'..'',,,,'''''',,,,,,.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl'.....',,'..':lc,.',,,,.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkd:..,'''cdONMWKo'.',,.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.'.;OWMMMMMMW0c'',.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.'oXMMMMMMMMMMWk;..,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOlOWMMMMMMMMMMMMMXo:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ChippysWorld is ERC721, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _totalSupply;

    uint public constant MAX_CHIPS = 2500;
    uint256 public PRICE = .075 ether;
    uint public constant MAX_MINT = 3;

    bool public phase1 = false;
    bool public phase2 = false;

    bool private devTeamMinted = false;

    mapping(address => uint) claims;
    mapping(address => uint) mints;
    mapping(address => uint) publicMints;

    IERC721 private sharedStorefront;

    uint _supply;
    bytes32 immutable public claimRoot;
    bytes32 immutable public mintRoot;

    string _baseURL = "";

    constructor(bytes32 _claimRoot, bytes32 _mintRoot) ERC721("ChippysWorld", "CHIP") {
        claimRoot = _claimRoot;
        mintRoot = _mintRoot;
    }

    function mint(address _to) internal {
        _totalSupply.increment();
        _safeMint(_to, _totalSupply.current());
    }

    function claim(uint256 count, uint256 allowance, bytes32[] calldata proof) public {
        require(phase1, "phase 1 not enabled");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof, claimRoot), "invalid proof");
        require(claims[msg.sender] + count <= allowance, "exceeds claim supply");
        require(_totalSupply.current() + count <= MAX_CHIPS, "exceeds max supply");
        claims[msg.sender] += count;

        for(uint i; i < count; i++) {
            mint(msg.sender);
        }
    }

    function allowListMint(uint256 amount, uint256 allowance, bytes32[] calldata proof) public payable {
        require(phase1, "phase 1 not enabled");
        require(amount * PRICE == msg.value, "Insufficient funds.");

        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof, mintRoot), "invalid proof");
        require(mints[msg.sender] + amount <= allowance, "exceeds allowed mints");
        require(_totalSupply.current() + amount <= MAX_CHIPS, "exceeds max supply");
        mints[msg.sender] += amount;

        for(uint i; i < amount; i++) {
            mint(msg.sender);
        }
    }

    function publicMint(uint256 quantity, uint256 nonce, bytes memory signature) public payable {
        require(_totalSupply.current() + quantity <= MAX_CHIPS, "exceeds max supply");
        require(quantity * PRICE == msg.value, "Insufficient funds.");
        require(phase2, "public mint not enabled");
        require(publicMints[msg.sender] + quantity <= MAX_MINT, "max minted for wallet");

        // check that the signature is valid
        isValid(quantity, nonce, signature);

        for(uint i; i < quantity; i++) {
            mint(msg.sender);
        }

        publicMints[msg.sender] += quantity;
    }

    function teamMint(uint amount) public onlyOwner {
        require(_totalSupply.current() + amount <= MAX_CHIPS, "exceeds max supply");
        require(!devTeamMinted, "already minted");

        for(uint i; i < amount; i++) {
            mint(msg.sender);
        }

        devTeamMinted = true;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool valid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == owner();
    }

    function isValid(uint256 quantity, uint256 nonce, bytes memory signature) public view {
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, nonce, quantity));
        require(
            isValidSignature(msgHash, signature),
            "Invalid signature"
        );
    }

    function flipPhase1() public onlyOwner {
        phase1 = !phase1;
    }

    function flipPhase2() public onlyOwner {
        phase2 = !phase2;
    }

    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function withdraw() public {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to send to owner.");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        _baseURL = _uri;
    }

    function remainingClaims(address addr, uint allowance, bytes32[] calldata proof) external view returns (uint){
        string memory payload = string(abi.encodePacked(addr));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof, claimRoot), "invalid proof");
        return allowance - claims[addr];
    }

    function remainingMints(address addr, uint allowance, bytes32[] calldata proof) external view returns (uint){
        string memory payload = string(abi.encodePacked(addr));
        require(_verify(_leaf(Strings.toString(allowance), payload), proof, mintRoot), "invalid proof");
        return allowance - mints[addr];
    }

    function totalMinted(address addr) external view returns (uint) {
        return publicMints[addr];
    }
}