// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";

contract AccessControl {
  address payable public ceoAddress;

  constructor() {
    ceoAddress = payable(msg.sender);
  }

  modifier onlyCEO() {
    require(msg.sender == ceoAddress, '');
    _;
  }

  function setCEO(address payable _newCEO) public onlyCEO {
    require(_newCEO != address(0), '');

    ceoAddress = _newCEO;
  }
}

contract DigiPet is AccessControl, ERC721 {
  using SafeMath for uint256;

  event CreatedPetCollection(
    address indexed creator,
    uint256 indexed petCollectionId,
    uint64 indexed quantity,
    string category
  );
  event SetPrice(uint256 indexed newPrice, uint256 indexed petCollectionId);
  event StartOrStoppedSelling(
    bool indexed state,
    uint256 indexed petCollectionId
  );
  event StartOrStoppedLending(
    bool indexed state,
    uint256 indexed petCollectionId
  );
  event AddedWearables(address indexed creator, uint256 indexed tokenId);
  event RemovedWearables(address indexed creator, uint256 indexed tokenId);
  event PetCollectionMetadata(
    string indexed url,
    uint256 indexed petCollectionId
  );
  event MintedPet(
    uint256 indexed petId,
    uint256 indexed petCollectionId,
    address indexed newOwner,
    uint256 price
  );
  event PetName(string indexed name, uint256 indexed petId);
  event PetDescription(string indexed description, uint256 indexed petId);

  constructor() ERC721('DigiPet', 'DP') {}

  mapping(string => uint256) private petNameToPetId;
  mapping(uint256 => address) private petIdToOwner;
  mapping(uint256 => address) private petIdToApproved;
  mapping(address => uint256) private ownerPetCount;
  mapping(uint256 => address payable) private petCollectionIdToCreator;
  mapping(uint256 => uint64) private collectionIdToPetsRemaining;
  mapping(address => uint64) private creatorPetCollectionCount;
  mapping(uint256 => uint256) private collectionIdToTotalVolume;
  mapping(uint256 => string) private collectionIdtoMetadataUrl;

  struct Pet {
    address owner;
    string category;
    Gender gender;
    string name;
    uint48 birthday;
    string description;
    uint256 petCollectionId;
    string imageCid;
    string modelCid;
  }

  struct PetCollection {
    address creator;
    string category;
    Gender gender;
    string name;
    uint48 birthday;
    string description;
    uint256[] wearables;
    uint256 price;
    bool forSale;
    bool forLoan;
    uint64 quantity;
    string imageCid;
    string modelCid;
  }

  Pet[] private pets;
  PetCollection[] private petCollections;
  uint256 public priceCreation = 0;
  uint16 public maxQuantity = 999;
  uint256 public houseFee = 500;
  uint256 public minPetPrice = 0;
  enum Gender {
    MALE,
    FEMALE,
    NEUTRAL
  }

  function createPetCollection(
    string memory _name,
    uint64 _quantity,
    string memory _category,
    Gender _gender,
    string memory _description,
    string memory _imageCid,
    string memory _modelCid
  ) public payable {
    bytes memory nameBytes = bytes(_name);
    bytes memory categoryBytes = bytes(_category);
    bytes memory descriptionBytes = bytes(_description);
    require(msg.sender != address(0), '');
    require(nameBytes.length <= 24, 'Name more than 24 characters');
    require(msg.value >= priceCreation, 'Amount sent too low');
    require(_quantity > 0, 'Quantity must be greater than 0');
    require(_quantity <= maxQuantity, 'Quantity exceeds maximum');
    require(categoryBytes.length <= 18, 'Category > 18 characters');
    require(descriptionBytes.length <= 200, 'Description > 200 characters');

    uint48 birthday = uint48(block.timestamp);

    PetCollection memory petCollection = PetCollection({
      creator: msg.sender,
      category: _category,
      gender: _gender,
      name: _name,
      birthday: birthday,
      description: _description,
      wearables: new uint256[](0),
      price: minPetPrice,
      forSale: false,
      forLoan: true,
      quantity: _quantity,
      imageCid: _imageCid,
      modelCid: _modelCid
    });
    petCollections.push(petCollection);
    uint256 petCollectionId = petCollections.length - 1;

    collectionIdToPetsRemaining[petCollectionId] = _quantity;
    creatorPetCollectionCount[msg.sender]++;
    petCollectionIdToCreator[petCollectionId] = payable(msg.sender);

    emit CreatedPetCollection(
      msg.sender,
      petCollectionId,
      _quantity,
      _category
    );
  }

  function setPetPrice(uint256 _newPrice, uint256 _petCollectionId) public {
    require(_ownsPetCollection(msg.sender, _petCollectionId), 'Sender does not own pet collection');
    require(_newPrice >= minPetPrice, 'Price below minimum');

    petCollections[_petCollectionId].price = _newPrice;

    emit SetPrice(_newPrice, _petCollectionId);
  }

  function startOrStopSelling(bool _state, uint256 _petCollectionId) public {
    require(_ownsPetCollection(msg.sender, _petCollectionId), 'Sender does not own pet collection');

    petCollections[_petCollectionId].forSale = _state;

    emit StartOrStoppedSelling(_state, _petCollectionId);
  }

  function startOrStopLending(bool _state, uint256 _petCollectionId) public {
    require(_ownsPetCollection(msg.sender, _petCollectionId), 'Sender does not own pet collection');

    petCollections[_petCollectionId].forLoan = _state;

    emit StartOrStoppedLending(_state, _petCollectionId);
  }

  function addWearablesCollection(
    uint256 _newWearablesTokenId,
    uint256 _petCollectionId
  ) public {
    require(msg.sender != address(0), '');
    require(_ownsPetCollection(msg.sender, _petCollectionId), 'Sender does not own pet collection');

    petCollections[_petCollectionId].wearables.push(_newWearablesTokenId);

    emit AddedWearables(msg.sender, _newWearablesTokenId);
  }

  function removeWearablesCollection(
    uint256 _wearablesTokenId,
    uint256 _petCollectionId
  ) public {
    require(msg.sender != address(0), '');
    require(_ownsPetCollection(msg.sender, _petCollectionId), 'Sender does not own pet collection');

    uint256[] storage wearablesArray = petCollections[_petCollectionId]
      .wearables;

    for (uint256 i = 0; i < wearablesArray.length; i++) {
      if (wearablesArray[i] == _wearablesTokenId) {
        for (uint j = i; j < wearablesArray.length - 1; j++) {
          wearablesArray[j] = wearablesArray[j + 1];
        }
        wearablesArray.pop();
      }
    }

    emit RemovedWearables(msg.sender, _wearablesTokenId);
  }

  function setPetCollectionMetadataUrl(
    string memory _url,
    uint256 _petCollectionId
  ) public {
    require(msg.sender != address(0), '');
    require(_ownsPetCollection(msg.sender, _petCollectionId), 'Sender does not own pet collection');

    collectionIdtoMetadataUrl[_petCollectionId] = _url;

    emit PetCollectionMetadata(_url, _petCollectionId);
  }

  function mintPetFromCollection(uint256 _petCollectionId) public payable {
    uint64 petsRemaining = getNumberOfPetsRemaining(_petCollectionId);
    bool collectionForSale = petCollections[_petCollectionId].forSale;
    uint256 price = getPetPrice(_petCollectionId);
    require(msg.sender != address(0), '');
    require(msg.value >= price, 'Amount sent too low');
    require(collectionForSale == true, 'Collection not for sale');
    require(petsRemaining > 0, 'Collection sold out');

    collectionIdToTotalVolume[_petCollectionId] += msg.value;
    collectionIdToPetsRemaining[_petCollectionId]--;

    uint256 contractCut = price.mul(houseFee).div(10000);
    address payable creator = getCollectionCreator(_petCollectionId);
    creator.transfer(price.sub(contractCut));

    Pet memory pet = Pet({
      owner: msg.sender,
      category: petCollections[_petCollectionId].category,
      gender: petCollections[_petCollectionId].gender,
      name: '',
      birthday: petCollections[_petCollectionId].birthday,
      description: petCollections[_petCollectionId].description,
      petCollectionId: _petCollectionId,
      imageCid: petCollections[_petCollectionId].imageCid,
      modelCid: petCollections[_petCollectionId].modelCid
    });
    pets.push(pet);
    uint256 petId = pets.length - 1;

    _transfer(address(0), msg.sender, petId);

    emit MintedPet(petId, _petCollectionId, msg.sender, price);
  }

  function setPetName(string memory _name, uint256 _petId) public {
    bytes memory nameBytes = bytes(_name);
    require(_ownsPet(msg.sender, _petId), 'Sender does not own pet');
    require(nameBytes.length > 0, 'Name is 0 characters');
    require(nameBytes.length <= 24, 'Name more than 24 characters');
    require(petNameToPetId[_name] == 0, 'Name already registered');

    petNameToPetId[_name] = _petId;

    string memory oldName = pets[_petId].name;
    if (bytes(oldName).length != 0) {
      petNameToPetId[oldName] = 0;
    }

    pets[_petId].name = _name;

    emit PetName(_name, _petId);
  }

  function setPetDescription(
    string memory _description,
    uint256 _petId
  ) public {
    bytes memory descriptionBytes = bytes(_description);
    require(_ownsPet(msg.sender, _petId), 'Sender does not own pet');
    require(descriptionBytes.length <= 200, 'More than 200 characters');

    pets[_petId].description = _description;

    emit PetDescription(_description, _petId);
  }

  function setCreactionPrice(uint256 _newPrice) public onlyCEO {
    priceCreation = _newPrice;
  }

  function setMaxQuantity(uint16 _newQuantity) public onlyCEO {
    maxQuantity = _newQuantity;
  }

  function setHouseFee(uint256 _newFee) public onlyCEO {
    require(_newFee >= 100, 'Value must be at least 100');

    houseFee = _newFee;
  }

  function setMinPetPrice(uint256 _minPrice) public onlyCEO {
    minPetPrice = _minPrice;
  }

  function getContractBalance() public view returns (uint256) {
    uint256 balance = address(this).balance;

    return balance;
  }

  function withdrawBalance(uint256 _amount) public onlyCEO {
    require(
      _amount <= address(this).balance,
      'Amount exceeds contract balance'
    );

    if (_amount == 0) {
      _amount = address(this).balance;
    }

    ceoAddress.transfer(_amount);
  }

  function getPetCollectionData(
    uint256 _petCollectionId
  )
    public
    view
    returns (
      address _creator,
      string memory _name,
      string memory _category,
      string memory _imageCid,
      string memory _modelCid,
      bool _forSale,
      bool _forLoan,
      uint256 _price,
      uint64 _remaining
    )
  {
    uint64 petsRemaining = getNumberOfPetsRemaining(_petCollectionId);

    _creator = petCollections[_petCollectionId].creator;
    _name = petCollections[_petCollectionId].name;
    _category = petCollections[_petCollectionId].category;
    _imageCid = petCollections[_petCollectionId].imageCid;
    _modelCid = petCollections[_petCollectionId].modelCid;
    _forSale = petCollections[_petCollectionId].forSale;
    _forLoan = petCollections[_petCollectionId].forLoan;
    _price = petCollections[_petCollectionId].price;
    _remaining = petsRemaining;
  }

  function getPetCollectionDetails(
    uint256 _petCollectionId
  )
    public
    view
    returns (
      Gender _gender,
      uint48 _birthday,
      string memory _description,
      uint256[] memory _wearables,
      uint64 _quantity
    )
  {
    _gender = petCollections[_petCollectionId].gender;
    _birthday = petCollections[_petCollectionId].birthday;
    _description = petCollections[_petCollectionId].description;
    _wearables = petCollections[_petCollectionId].wearables;
    _quantity = petCollections[_petCollectionId].quantity;
  }

  function getPetData(
    uint256 _petId
  )
    public
    view
    returns (
      address _owner,
      string memory _category,
      Gender _gender,
      string memory _name,
      uint48 _birthday,
      string memory _description,
      uint256 _petCollectionId,
      string memory _imageCid,
      string memory _modelCid
    )
  {
    _owner = pets[_petId].owner;
    _category = pets[_petId].category;
    _gender = pets[_petId].gender;
    _name = pets[_petId].name;
    _birthday = pets[_petId].birthday;
    _description = pets[_petId].description;
    _petCollectionId = pets[_petId].petCollectionId;
    _imageCid = pets[_petId].imageCid;
    _modelCid = pets[_petId].modelCid;
  }

  function getAllOwners() public view returns (address[] memory) {
    uint256 total = totalSupply();
    address[] memory owners = new address[](total);

    for (uint256 i = 0; i < total; i++) {
      owners[i] = petIdToOwner[i];
    }

    return owners;
  }

  function getPetsOf(address _owner) public view returns (uint256[] memory) {
    uint256 petCount = balanceOf(_owner);

    if (petCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](petCount);
      uint256 total = totalSupply();
      uint256 resultIndex = 0;

      for (uint256 i = 0; i < total; i++) {
        if (petIdToOwner[i] == _owner) {
          result[resultIndex] = i;
          resultIndex++;
        }
      }

      return result;
    }
  }

  function getPetCollectionsOf(
    address _creator
  ) public view returns (uint256[] memory) {
    uint64 petCollectionCount = creatorPetCollectionCount[_creator];

    if (petCollectionCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](petCollectionCount);
      uint256 total = petCollections.length;
      uint256 resultIndex = 0;

      for (uint256 i = 0; i < total; i++) {
        if (petCollectionIdToCreator[i] == _creator) {
          result[resultIndex] = i;
          resultIndex++;
        }
      }

      return result;
    }
  }

  function getPetCollectionCount(
    address _creator
  ) public view returns (uint256) {
    uint256 _count = creatorPetCollectionCount[_creator];

    return _count;
  }

  function getNumberOfPetsRemaining(
    uint256 _petCollectionId
  ) public view returns (uint64) {
    uint64 number = collectionIdToPetsRemaining[_petCollectionId];

    return number;
  }

  function getCollectionCreator(
    uint256 _petCollectionId
  ) public view returns (address payable) {
    address payable creator = petCollectionIdToCreator[_petCollectionId];

    return creator;
  }

  function getCollectionMetadataUrl(
    uint256 _petCollectionId
  ) public view returns (string memory) {
    string memory url = collectionIdtoMetadataUrl[_petCollectionId];

    return url;
  }

  function getPetPrice(uint256 _petCollectionId) public view returns (uint256) {
    return petCollections[_petCollectionId].price;
  }

  function getCollectionTotalVolume(
    uint256 _petCollectionId
  ) public view returns (uint256) {
    return collectionIdToTotalVolume[_petCollectionId];
  }

  function getNumberOfCollections() public view returns (uint256) {
    uint256 number = petCollections.length;

    return number;
  }

  function nameToPetId(string memory _petName) public view returns (uint256) {
    return petNameToPetId[_petName];
  }

  function totalSupply() public view returns (uint256) {
    uint256 supply = pets.length;

    return supply;
  }

  function transfer(address _to, uint256 _petId) public {
    require(_to != address(0), '');
    require(_ownsPet(msg.sender, _petId), 'Sender does not own pet');

    _transfer(msg.sender, _to, _petId);
  }

  function _approved(address _to, uint256 _petId) private view returns (bool) {
    return petIdToApproved[_petId] == _to;
  }

  function _ownsPet(
    address _claimant,
    uint256 _petId
  ) private view returns (bool) {
    return petIdToOwner[_petId] == _claimant;
  }

  function _ownsPetCollection(
    address _claimant,
    uint256 _petCollectionId
  ) private view returns (bool) {
    return petCollectionIdToCreator[_petCollectionId] == _claimant;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _petId
  ) internal virtual override {
    ownerPetCount[_to]++;
    petIdToOwner[_petId] = _to;
    pets[_petId].owner = _to;

    if (_from != address(0)) {
      ownerPetCount[_from]--;
      delete petIdToApproved[_petId];
    }

    emit Transfer(_from, _to, _petId);
  }

  function balanceOf(address _owner) public view override returns (uint256) {
    uint256 balance = ownerPetCount[_owner];

    return balance;
  }

  function ownerOf(uint256 _petId) public view override returns (address) {
    address owner = petIdToOwner[_petId];

    return owner;
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _petId
  ) public override {
    require(_to != address(0), '');
    require(_ownsPet(_from, _petId), 'From does not own pet');
    require(_approved(msg.sender, _petId), 'Transfer not approved');

    _transfer(_from, _to, _petId);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _petId
  ) public override {
    require(_to != address(0), '');
    require(_ownsPet(_from, _petId), 'From does not own pet');
    require(_approved(msg.sender, _petId), 'Transfer not approved');

    _transfer(_from, _to, _petId);
  }

  function approve(address _to, uint256 _petId) public override {
    require(_ownsPet(msg.sender, _petId), 'Sender does not own pet');

    petIdToApproved[_petId] = _to;

    emit Approval(msg.sender, _to, _petId);
  }

  function tokenURI(
    uint256 _petId
  ) public view override returns (string memory) {
    uint256 collectionId = pets[_petId].petCollectionId;
    string memory uri = collectionIdtoMetadataUrl[collectionId];

    return uri;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);

    return a - b;
  }
}
