// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// @title: ChAOS
// @creator: Dana Taylor
// @author: @pepperonick, with help from @andrewjiang

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//  0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000OO000OOOOOOOOOO0000000  //
//  0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000OO000OOOOOOOOOOOOO0000  //
//  000000000000000000000000000000000000000OOOkkOOOkkkOO000000000000000000000000000000000000000000OO000OOOOOOOOOOOOO0000  //
//  0000000000000000000000000000000000O000Oxool::cc;;:clldxkO000000000000000000000000000000O000000OO000OOOOOOOOOOOOO0000  //
//  00000000000000000000000000000000000OOOkl;;'. ..........,:ok00O00O00000000000000000000000000000OO000OOOOOOOOOOOOOO000  //
//  000000000000000000000000000000000OOOOkxc...              .'ldk00000000000000000000000000000000OO000OOOOOOOOOOOOOOOOO  //
//  00000000000000000000000O0000000OOkdl:;,..                  ..;xOO00000000000000000000000000000OO000OOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000OOOOxlc;.....           ....       .:kOO00000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000O00Ox:'''......        ..;lddoc;,...  .cO0000OO0000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000000x;.;c,....       ...;ok00OOxdl:'.  .'dOOO00000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000O0Oc'co:'...        .'ck00KK0Okxoc,.   .ckOOO00000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000k;;l'.....         .:x0K0kdllc:;,.   .;xOOO00000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000k:,'.              ..:xOxlc:;,,,'..   'dkkOO0000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000Ol'...            ..:lxkddxdc:cl:..   .ckOO00000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  0000000000000000000000000OOo,...            .:ddkkddkOkxdo;.  ...'ldk0000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  0000000000000000000000000Okl;,'.           .,coddoccxkxoc;..  .. .,ok00OO00000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  0000000000000000000000000Okdc,...  .        .:ooooloxxo:;'..   . .;dOO0OO00OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  0000000000000000000000000kdc,....           .,:cldollol:;,.    ...;xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000kl;;;,'..            .;loddlloc;,.  .  .'.;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000x;,:;,;'.             .coddoc:,..   .  .'.;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000Okl:lodo;.               .'''.......   .'..:kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000OOOxxkkl'.                .',,,,;;'.   ...'oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000OO0OOOkc.                 .,;:ccc:'.     .,oxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000000OOx:'.                .';:cll:'.     .:odxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000OOOkl,..                .,;:clc'.    .,ldxkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000000kc:,.                .:::cc;...  .'codxkOOkkxdkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000000kddc.               .;lcc:,....  .coddxkOOkkdoldOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  00000000000000000000000000000OOko;.               ':lc;,'.....,cloxkO00Oxdl:cxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  0000000000000000000000000000000kxl,..             .;c::,. ..';clloxkO00Oxdoc;lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  0000000000000000000000000000000OOd:'.             .;ll:'. .';coolodkO00Okdol:cxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000000000000kl;.   ..,,,,''...,lodc. .';:looddxkO0Okxdl:cxOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000000000000kl,. .;ldxxxddolc;,:odd;....':lodxkkOOOkxdoc:dOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO  //
//  000000000000000000000000000000000k:'.'lxkkkkkxxdddoc:coo:',;,..;:ldxkkOOkxdoc:okkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0  //
//  000000000000000000000000000000000kc,;okO0KK0Oxdddollc:cc;;lol:'.';oxkkOOkxdoc:okkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00  //
//  000000000000000000000000000000000kccoxk0000Okxxxdollccc:;:oddo;';:ldxkkkxxdl::oOkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOO000  //
//  000000000000000000000000000000000xodxxk000Okxxxxdoolccccc::lloc;:cldxkkkxddl::dOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000  //
//  0000000000000000000000000000000K0xodxxkOOkkkkkxddoollccccc:;;:::ccldxkkkxdol:;dOkOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000000  //
//  000000000000000000KKK0000000000KOdoddxxxxxkkkxdooolllllllcc::;;;::coxkkkkxol:;oOOOOOOOOOOOOOOOOOOOOOOOOOOOO000000000  //
//  000000000000000000KKKKK00000000KOdoxdoddxxxxxxolcclllllllcccc::;,,;oxkkkkxol:;oOOOOOOOOOOOOOOOOOOOOOOOOOO00000000000  //
//  0000000000000000000KKKK00000000KOdoxxdddddddddol:::cloollccccc::;,,lkkOOkxolc:okOOOOOOOOOOOOOOOOOOOOOOOO000000000000  //
//  00000000000000000KKKKKKK0000000KOooxxdooddoooooolc:::loollccccc::;;lkOOkkdolc;lkOOOOOOOOOOOOOOOOOOOOOO00000000000000  //
//  000000000000KKKKKKKKK0000000000Kkooddolooooooooolll:;:lollccccc::::okOkkxdolc;lkOkkkOOOOOOOOOOOOOOOOOO00000000000000  //
//  000KKK00KKKKKKKKKKKKK00000000000kooddl::loooooooolllc::lolcccccc:::okkkxxdolc;;lkkkkkkOOOOOOOOOOOOOOO000000000000000  //
//  00KKKK0KKKKKKKKKKKKKKKKK00000000kooool;':looooooolllc:;collccccc:::lxkkxdoolc:,;dOkkkkOOOOOOOOOOOOOOOOOO000000000000  //
//  00KKKKKKKKKKKKKKKKKKKKKK00000000koloooc,,cllooooollllc::lolllccc::;cdxxxdollc:,,okkkkkkOOOOOOOOOOOOOO000000000000000  //
//  0KKKKKKKKKKKKKKKKKKKKKKKK0000000Odloodol;:lllloollllcc:;collllccc:;:oxxxdolcc;''cxkkkkkOOOOOOOOOOOO00000000000000000  //
//  KKKKKKKKKKKKKKKKKKKKKKKKKKK000000kolooddlcclllooolllcc:;:lllllccc:;:oxxxdolc:;'';dkkkkkOkOOOOOOOO0000000000000000000  //
//  KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0K0xloodddoccllloollcc::,;cllllccc:;:odxdoolc:,'',lkOkkOOOOOOOOOO00000000000000000000  //
//  KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xllodddoc::cllllcc::,,:llccccccclodddolc:;,''';dOOkOOOOOOOOOO00000000000000000000  //
//  KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK000OOxlloodxddc;;clllc::;,,;ccccccloodddoolcc;,''',,lkkOOOkOOOOOOOO0000000000000000000  //
//  KKKKKKKKKKKKKKKKKKKKKKKKKK00Okxdolcc::cloddddl;:clcc:;;,',:::cloddxddolcc::;,'',,,lkOOOOOOOOOOOOO0000000000000000KKK  //
//  KKKKKKKKKKKKKKKKKKKK00OOkkxdollcccccc::cclodddolcc::;;,,',clooddxxdolcc::;,,'',,,;oOOOOOOOOOOOOOOO0000000000000000KK  //
//  KKKKKKKKKKKKKKK00OOkkxxddooollcccccccccc:cloddxxoc;,,,,;coxxxxxddolcc::;;,,,,,,,,cxOOOkOOOOOOOOOO000000000000000000K  //
//  KKKKKKKKKKKK00Okxxxdddxxddoolcccccccccccc::coddxxdl;;codxkxxddollcc:;,,,,,,,,,,,:dkkOOOOOOOOOOOOO0000000000000000000  //
//  KKKKKKKKKKK0kxxkkxxdddxxxdolc:::::::::::::;;codxxxddxxkxxdoollcc::,''''',,,,,,,:dkOOOOOOOOOOOOOOO0000000000000000000  //
//  KKKKKKKKKK0xdkOOOkxddxxxdoc::::::::ccccc:::;;coxxxkkxddoollcc:;,'......'''''',:dkkOkkkkOOOOOOOO000000000000000000000  //
//  KKKKKKKKKKOxxkO00kkkxxxkxxdooooooooooooooloodxxxxxdoollcc:;,'..     .......',cdkkkkkOOOOOOOO000000000000000000000000  //
//  KKKKKKKKKKOxkkO00000Okkkkkxxxddddddddddxxxxxxxdoollcc:;,,'........    ...,:cclloxkkOOOOOOO00000000000000000000000000  //
//  KKKKKKKKKKOxxkkOO000OOkkxxdddxxxxkkkkkkkxdddollcc:;;,;;:::cc:;'''''....,;cloodooodxkOOOO000000000000000000000KKKKKKK  //
//  KKKKKKKKKKKOxxkkkkkkkxxdoolloxkxxkkkkxddoolllc:;,,;:lodxddoool:;;ccllccccclddxxxxdxkkOOOOO00000000000000000KKKKKKKKK  //
//  KKKKXXXXKKXK0kxxdxxxxdddddxxkxxxxxxxdoollccc:;;;;:coxxxxddoc:cll::loddddddddxkkkkkOOOOOOOOOOkkO00000000000KKKKKKKKKK  //
//  XXXXXXXXXXXXKK0Okdoooodxxxxxdxxdddoollc:::::::::ccclooodoloolc;cc:coddxxkxxxxkkOOOO0000OOOOOOOkOO00000000KKKKKKKKKKK  //
//  XXXXXXXXXXXXKKKK0kxdodddoodddddooollc::::::ccccc::::colcoocldo:',:;:cllllooodddxxxxxkkxxxxxddxkkkOkO0000KKKKKKKKKKKK  //
//  XXXXXXXXXXKKKK00OOkxxdllloooollllc;'.',;::ccllllllllldo::o:,;:c;;clldddddddddddddoooooolllllcclloxkxxO00KKKKKKKKKKKK  //
//  XXXXXXXXXKK0000000OOkxddolllcclc:;,,;clodxkkkkkkOOkkkkkxdddoodddxkOOOOOOOOOOOOOOOOOOOOkkkkxxxxddodxdok0KKKKKKKKKKKKK  //
//  XXXXXXXKKK00000000OOOOOkkkkkkkkxxxkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000KKKK0000OOOOOOkkO0KKKKKKKKKKKKKK  //
//  XXXXXXXKKKK00000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000KKKKKKKKKKK000000KKKKKKKKKKKKKKKK  //
//  XXXXXXXXKKKK000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK  //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import '@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol';
import '@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol';
import '@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

contract ChAOS is AdminControl, ICreatorExtensionTokenURI {
    enum ContractStatus {
        Paused,
        Premint,
        Public,
        Closed
    }

    using Strings for uint256;

    ContractStatus public contractStatus = ContractStatus.Paused;
    address private _creator;
    address private _writerAddress;
    uint256 public _price;
    bytes32 public _merkleRoot;
    uint256 public _maxPremintPerWallet = 2;
    uint256 public _maxMintPerTransaction = 2;
    bool public _isRevealed = false;
    string public _prerevealImageURI;
    string public _prerevealAnimatedURI;
    uint256 public totalSupply = 0;
    string private baseURI;
    uint16 public _maxSupply = 1000;

    // Used to make sure wallet gets at most 2 mints during premint
    mapping(address => uint256) public addressToMint;

    constructor(
        address creator,
        uint256 price,
        address writerAddress,
        string memory prerevealImageURI,
        string memory prerevealAnimatedURI
    ) {
        _creator = creator;
        _price = price;
        _writerAddress = writerAddress;
        _prerevealImageURI = prerevealImageURI;
        _prerevealAnimatedURI = prerevealAnimatedURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    function configure(address creator) public adminRequired {
        _creator = creator;
    }

    function setContractStatus(ContractStatus status) public adminRequired {
        contractStatus = status;
    }

    function setMaxSupply(uint16 maxSupply) public adminRequired {
        _maxSupply = maxSupply;
    }

    function setPrerevealImageURI(string calldata prerevealImageURI)
        public
        adminRequired
    {
        _prerevealImageURI = prerevealImageURI;
    }

    function setPrerevealAnimatedURI(string calldata prerevealAnimatedURI)
        public
        adminRequired
    {
        _prerevealAnimatedURI = prerevealAnimatedURI;
    }

    function setIsRevealed(bool isRevealed) public adminRequired {
        _isRevealed = isRevealed;
    }

    modifier isPaused() {
        require(
            contractStatus == ContractStatus.Paused,
            'Contract cannot be in premint or open for minting'
        );
        _;
    }

    modifier isPublic() {
        require(
            contractStatus == ContractStatus.Public,
            'Contract must be open for minting'
        );
        _;
    }

    modifier isPublicOrPremint() {
        require(
            contractStatus == ContractStatus.Public ||
                contractStatus == ContractStatus.Premint,
            'Contract must be open for premint or public mint'
        );
        _;
    }

    modifier withRightQuantities(uint256 quantity) {
        require(
            quantity <= _maxMintPerTransaction,
            string(
                abi.encodePacked(
                    'Cannot mint more than ',
                    Strings.toString(_maxMintPerTransaction),
                    ' per transaction'
                )
            )
        );
        require(
            quantity + totalSupply <= _maxSupply,
            'Cannot mint more than max supply'
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function canPremint(address account, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(proof, _merkleRoot, generateMerkleLeaf(account));
    }

    function premint(uint256 quantity, bytes32[] calldata proof)
        public
        payable
        isPublicOrPremint
        withRightQuantities(quantity)
    {
        require(canPremint(msg.sender, proof), 'Failed to verify wallet');

        require(
            addressToMint[msg.sender] + quantity <= _maxPremintPerWallet,
            string.concat(
                'Cannot premint more than ',
                Strings.toString(_maxPremintPerWallet),
                ' per wallet'
            )
        );

        require(msg.value == _price * quantity, 'Wrong quantity of ETH sent');

        IERC721CreatorCore(_creator).mintExtensionBatch(
            msg.sender,
            uint16(quantity)
        );

        totalSupply += quantity;
        addressToMint[msg.sender] += quantity;
    }

    function mint(uint256 quantity)
        public
        payable
        callerIsUser
        isPublic
        withRightQuantities(quantity)
    {
        require(msg.value == _price * quantity, 'Wrong quantity of ETH sent');

        IERC721CreatorCore(_creator).mintExtensionBatch(
            msg.sender,
            uint16(quantity)
        );

        totalSupply += quantity;
    }

    function setPrice(uint256 price) public adminRequired {
        _price = price;
    }

    function setMaxPremintPerWallet(uint256 max) public adminRequired {
        _maxPremintPerWallet = max;
    }

    function setMaxMintPerTransaction(uint256 max) public adminRequired {
        _maxMintPerTransaction = max;
    }

    function generateMerkleLeaf(address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function setMerkleRoot(bytes32 merkleRoot) public adminRequired {
        _merkleRoot = merkleRoot;
    }

    function setBaseURI(string memory _baseURI) public adminRequired {
        baseURI = _baseURI;
    }

    function tokenURI(address creator, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(creator == _creator, 'Invalid token');
        require(tokenId <= totalSupply, 'Token does not exist yet');

        if (!_isRevealed) {
            return
                string.concat(
                    'data:application/json;utf8,',
                    '{"name":"ChAOS #',
                    tokenId.toString(),
                    '",',
                    '"created_by":"Dana Taylor",',
                    '"description":"Chaos & Couture is a tell-all by Dana Taylor of over a decade worth of stories, challenges, and triumphs as a model in the highest spheres of the fashion industry. Her art is a testament of truth, self-exploration & personal growth. With a unique sense of creativity, Dana has taken her darkest hour and made a shining beacon of light. This collection is an inspiration to believe that you can be more than one thing in this life.\\n\\nArtist: Dana Taylor",',
                    '"image":"',
                    _prerevealImageURI,
                    '","image_url":"',
                    _prerevealImageURI,
                    '","animation_url":"',
                    _prerevealAnimatedURI,
                    '"}'
                );
        } else {
            return
                bytes(baseURI).length > 0
                    ? string.concat(baseURI, tokenId.toString(), '.json')
                    : '';
        }
    }

    function setWriterAddress(address writerAddress) public adminRequired {
        require(writerAddress != address(0), 'Writer address cannot be 0x0');
        _writerAddress = writerAddress;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Cannot withdraw more than balance');

        address creator = payable(to);
        address writer = payable(_writerAddress);

        bool success;

        (success, ) = creator.call{value: ((amount * 900) / 1000)}('');
        require(success, 'Transaction Unsuccessful');

        (success, ) = writer.call{value: ((amount * 100) / 1000)}('');
        require(success, 'Transaction Unsuccessful');
    }
}