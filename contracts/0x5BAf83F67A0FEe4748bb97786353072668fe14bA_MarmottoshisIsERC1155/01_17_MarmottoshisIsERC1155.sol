// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IMarmottoshisIsERC1155.sol";
import "./ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MarmottoshisIsERC1155 is IMarmottoshisIsERC1155, ERC1155, ERC2981, Ownable, ReentrancyGuard {

    string public name = "Marmottoshis";
    string public symbol = "WASAT";

    using Strings for uint;

    Step public currentStep;

    uint public constant maxToken = 21; // 21 different NFTs
    uint public constant maxSupply = 37; // 37 copies of each NFT

    uint public reservationPrice = 0.01727 ether; // Price of the reservation (21 USD ATM)
    uint public reservationNFTPrice = 0.04663 ether; // Price of the NFT for reservation list (56.7 USD ATM)
    uint public whitelistPrice = 0.0639 ether; // Price of whitelist mint (77.7 USD ATM)
    uint public publicPrice = 0.0639 ether; // Price of public mint (77.7 USD ATM)

    uint public balanceOfSatoshis = 0; // Balance of Satoshis (100000000 Satoshis = 1 Bitcoin)

    uint public currentReservationNumber = 0; // Current number of reservations purchased

    bytes32 public freeMintMerkleRoot; // Merkle root of the free mint
    bytes32 public firstMerkleRoot; // Merkle root of the first whitelist
    bytes32 public secondMerkleRoot; // Merkle root of the second whitelist

    mapping(uint => Metadata) public metadataById; // Artist by ID
    mapping(uint => uint) public supplyByID; // Number of NFTs minted by ID
    mapping(address => bool) public reservationList; // List of addresses that reserved (true = reserved)

    mapping(address => uint) public freeMintByWallet; // Number of NFTs minted by wallet for free mint
    mapping(address => uint) public reservationMintByWallet; // Number of reserved NFT mint by wallet
    mapping(address => uint) public firstWhitelistMintByWallet; // Number of first whitelist NFT mint by wallet
    mapping(address => uint) public secondWhitelistMintByWallet; // Number of second whitelist NFT mint by wallet

    mapping(uint => uint) public balanceOfSatoshiByID; // Balance of Satoshi by token ID

    address public marmott; // Marmott's address

    bool public isMetadataLocked = false; // Locks the metadata URI
    bool public isRevealed = false; // Reveal the NFTs

    constructor(address _marmott, string memory _uri) ERC1155(_uri) {
        marmott = _marmott;
    }

    // @dev see {IMarmottoshisIsERC1155-mint}
    function mint(uint idToMint, bytes32[] calldata _proof) public payable nonReentrant {
        require(
            currentStep == Step.FreeMint ||
            currentStep == Step.ReservationMint ||
            currentStep == Step.FirstWhitelistMint ||
            currentStep == Step.SecondWhitelistMint ||
            currentStep == Step.PublicMint
        , "Sale is not open");
        require(idToMint >= 1, "Nonexistent id");
        require(idToMint <= maxToken, "Nonexistent id");
        require(supplyByID[idToMint] + 1 <= maxSupply, "Max supply exceeded for this id");

        if (currentStep == Step.FreeMint) {
            require(isOnList(msg.sender, _proof, 0), "Not on free mint list");
            require(totalSupply() + 1 <= 77, "Max free mint supply exceeded");
            require(freeMintByWallet[msg.sender] + 1 <= 1, "You already minted your free NFT");
            freeMintByWallet[msg.sender] += 1;
            _mint(msg.sender, idToMint, 1, "");
        } else if (currentStep == Step.ReservationMint) {
            require(reservationList[msg.sender], "Not on reservation list");
            require(msg.value >= reservationNFTPrice, "Not enough ether");
            require(totalSupply() + 1 <= 477, "Max reservation mint supply exceeded");
            require(reservationMintByWallet[msg.sender] + 1 <= 1, "You already minted your reserved NFT");
            reservationMintByWallet[msg.sender] += 1;
            _mint(msg.sender, idToMint, 1, "");
        } else if (currentStep == Step.FirstWhitelistMint) {
            require(isOnList(msg.sender, _proof, 1), "Not on first whitelist");
            require(msg.value >= whitelistPrice, "Not enough ether");
            require(totalSupply() + 1 <= 577, "Max first whitelist mint supply exceeded");
            require(firstWhitelistMintByWallet[msg.sender] + 1 <= 1, "You already minted your first whitelist NFT");
            firstWhitelistMintByWallet[msg.sender] += 1;
            _mint(msg.sender, idToMint, 1, "");
        } else if (currentStep == Step.SecondWhitelistMint) {
            require(isOnList(msg.sender, _proof, 2), "Not on second whitelist");
            require(msg.value >= whitelistPrice, "Not enough ether");
            require(totalSupply() + 1 <= 777, "Max second whitelist mint supply exceeded");
            require(secondWhitelistMintByWallet[msg.sender] + 1 <= 1, "You already minted your second whitelist NFT");
            secondWhitelistMintByWallet[msg.sender] += 1;
            _mint(msg.sender, idToMint, 1, "");
        } else {
            require(msg.value >= publicPrice, "Not enough ether");
            require(totalSupply() + 1 <= 777, "Sold out");
            _mint(msg.sender, idToMint, 1, "");
        }
        supplyByID[idToMint]++;
        emit newMint(msg.sender, idToMint);
    }

    // @dev see {IMarmottoshisIsERC1155-updateStep}
    function updateStep(Step _step) external onlyOwner {
        currentStep = _step;
        emit stepUpdated(currentStep);
    }

    // @dev see {IMarmottoshisIsERC1155-updateMarmott}
    function updateMarmott(address _marmott) external {
        require(msg.sender == marmott || msg.sender == owner(), "Only Marmott or owner can update Marmott");
        marmott = _marmott;
    }

    // @dev see {IMarmottoshisIsERC1155-lockMetadata}
    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }

    // @dev see {IMarmottoshisIsERC1155-reveal}
    function reveal() external onlyOwner {
        isRevealed = true;
    }

    // @dev see {IMarmottoshisIsERC1155-updateURI}
    function updateURI(string memory _newUri) external onlyOwner {
        require(!isMetadataLocked, "Metadata locked");
        _uri = _newUri;
    }

    // @dev see {IMarmottoshisIsERC1155-addSats}
    function addSats(uint satoshis) external {
        require(msg.sender == marmott, "Only Marmott can add BTC");
        balanceOfSatoshis = balanceOfSatoshis + satoshis;
        uint divedBy = getNumberOfIdLeft();
        require(divedBy > 0, "No NFT left");
        uint satoshisPerId = satoshis / divedBy;
        for (uint i = 1; i <= maxToken; i++) {
            if (supplyByID[i] > 0) {
                balanceOfSatoshiByID[i] = balanceOfSatoshiByID[i] + satoshisPerId;
            }
        }
    }

    // @dev see {IMarmottoshisIsERC1155-subSats}
    function subSats(uint satoshis) external {
        require(msg.sender == marmott, "Only Marmott can sub BTC");
        require(balanceOfSatoshis >= satoshis, "Not enough satoshis in balance to sub");
        balanceOfSatoshis = balanceOfSatoshis - satoshis;
        uint divedBy = getNumberOfIdLeft();
        require(divedBy > 0, "No NFT left");
        uint satoshisPerId = satoshis / divedBy;
        for (uint i = 1; i <= maxToken; i++) {
            if (supplyByID[i] > 0) {
                require(balanceOfSatoshiByID[i] >= satoshisPerId, "Not enough satoshis in balance to sub (by id)");
                balanceOfSatoshiByID[i] = balanceOfSatoshiByID[i] - satoshisPerId;
            }
        }
    }

    // @dev see {IMarmottoshisIsERC1155-burnAndRedeem}
    function burnAndRedeem(uint _idToRedeem, string memory _btcAddress) public nonReentrant {
        require(_idToRedeem >= 1, "Nonexistent id");
        require(_idToRedeem <= maxToken, "Nonexistent id");
        require(currentStep == Step.SoldOut, "You can't redeem satoshis yet");
        require(balanceOf(msg.sender, _idToRedeem) >= 1, "Not enough Marmottoshis to burn");
        _burn(msg.sender, _idToRedeem, 1);
        uint satoshisToRedeem = redeemableById(_idToRedeem);
        require(satoshisToRedeem > 0, "No satoshi to redeem");
        balanceOfSatoshis = balanceOfSatoshis - satoshisToRedeem;
        balanceOfSatoshiByID[_idToRedeem] = balanceOfSatoshiByID[_idToRedeem] - satoshisToRedeem;
        supplyByID[_idToRedeem] = supplyByID[_idToRedeem] - 1;
        emit newRedeemRequest(msg.sender, _idToRedeem, 1, _btcAddress, satoshisToRedeem);
    }

    // @dev see {IMarmottoshisIsERC1155-reservationForWhitelist}
    function reservationForWhitelist() external payable nonReentrant {
        require(currentStep == Step.WLReservation, "Reservation for whitelist is not open");
        require(msg.value >= reservationPrice, "Not enough ether");
        require(reservationList[msg.sender] == false, "You are already in the pre-whitelist");
        require(currentReservationNumber + 1 <= 400, "Max pre-whitelist reached");
        currentReservationNumber = currentReservationNumber + 1;
        reservationList[msg.sender] = true;
        emit newReservation(msg.sender);
    }

    // @dev see {IMarmottoshisIsERC1155-redeemableById}
    function redeemableById(uint _id) public view returns (uint) {
        if (supplyByID[_id] == 0) {
            return 0;
        } else {
            return balanceOfSatoshiByID[_id] / supplyByID[_id];
        }
    }

    // @dev see {IMarmottoshisIsERC1155-getNumberOfIdLeft}
    function getNumberOfIdLeft() public view returns (uint) {
        uint numberOfIdLeft = 0;
        for (uint i = 1; i <= maxToken; i++) {
            if (supplyByID[i] > 0) {
                numberOfIdLeft = numberOfIdLeft + 1;
            }
        }
        return numberOfIdLeft;
    }

    // @dev see {IMarmottoshisIsERC1155-addMetadata}
    function addMetadata(uint[] memory _id, string[] memory _artists_names, string[] memory _marmot_name, string[] memory _links, string[] memory _uri) external onlyOwner {
        require(!isMetadataLocked, "Metadata locked");
        for (uint i = 0; i < _id.length; i++) {
            metadataById[_id[i]] = Metadata({
                id: _id[i],
                artist_name: _artists_names[i],
                marmot_name: _marmot_name[i],
                link: _links[i],
                uri: _uri[i]
            });
        }
    }

    // @dev see {IMarmottoshisIsERC1155-updateFreeMintMerkleRoot}
    function updateFreeMintMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMintMerkleRoot = _merkleRoot;
    }

    // @dev see {IMarmottoshisIsERC1155-updateFirstWhitelistMerkleRoot}
    function updateFirstWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        firstMerkleRoot = _merkleRoot;
    }

    // @dev see {IMarmottoshisIsERC1155-updateSecondWhitelistMerkleRoot}
    function updateSecondWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        secondMerkleRoot = _merkleRoot;
    }

    // @dev see {IMarmottoshisIsERC1155-updateReservationPrice}
    function updateReservationPrice(uint _reservationPrice) external onlyOwner {
        reservationPrice = _reservationPrice;
    }

    // @dev see {IMarmottoshisIsERC1155-updateReservationNFTPrice}
    function updateReservationNFTPrice(uint _reservationNFTPrice) external onlyOwner {
        reservationNFTPrice = _reservationNFTPrice;
    }

    // @dev see {IMarmottoshisIsERC1155-updateWLPrice}
    function updateWLPrice(uint _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    // @dev see {IMarmottoshisIsERC1155-updatePublicPrice}
    function updatePublicPrice(uint _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    // @dev see {IERC1155MetadataURI-uri}
    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId >= 1, "Nonexistent id");
        require(_tokenId <= maxToken, "Nonexistent id");
        if (!isRevealed) {
            return _uri;
        }
        string memory image = metadataById[_tokenId].uri;
        string memory marmot_name = metadataById[_tokenId].marmot_name;
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', marmot_name, '", "image": "', image, '", "description": "Realised by ', metadataById[_tokenId].artist_name, '. You can see more here : ', metadataById[_tokenId].link, ' .", "attributes": [{"trait_type": "Satoshis", "value": "', redeemableById(_tokenId).toString(), '"}, {"trait_type": "Remaining Copy", "value": "', supplyByID[_tokenId].toString(), '"}]}'
                    )
                )
            )
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    // @dev see {IMarmottoshisIsERC1155-totalSupply}
    function totalSupply() public view returns (uint) {
        uint supply = 0;
        for (uint i = 1; i <= maxToken; i++) {
            supply = supply + supplyByID[i];
        }
        return supply;
    }

    // @dev see {IMarmottoshisIsERC1155-withdraw}
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // @dev see {IMarmottoshisIsERC1155-isOnList}
    function isOnList(address _account, bytes32[] calldata _proof, uint _step) public view returns (bool) {
        if (_step == 0) {
            return _verify(_leaf(_account), _proof, freeMintMerkleRoot);
        } else if (_step == 1) {
            return _verify(_leaf(_account), _proof, firstMerkleRoot);
        } else if (_step == 2) {
            return _verify(_leaf(_account), _proof, secondMerkleRoot);
        } else {
            return false;
        }
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }


    // @dev see {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // @dev see {IMarmottoshisIsERC1155-setDefaultRoyalty}
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}