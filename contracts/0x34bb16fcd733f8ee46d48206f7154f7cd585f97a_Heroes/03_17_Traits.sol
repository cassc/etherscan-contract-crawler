// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HeroTraits {
  function getPantsLength() public pure returns (uint256) {
    return getPants().length;
  }

  function getPants() public pure returns (string[2][5] memory) {
    return [
      ["White Pants", "QmS1ugwVyGemvvcu8xhvYPLJcM9XiCzev19hL5S4118mvY"],
      ["Red Pants", "QmQRw479rzessc1ms2kcnKQCvCs2aQ1Ep25vK7xgo9cEJt"],
      ["Blue Pants", "QmePEJz87mRjQt9BmYib14Fcxn8j13Xkdj6MfYoUZbQi79"],
      ["Green Pants", "QmZ6sjTg936aJCM67NPsPcCjMphAYEWoyQXHNHduKzLyf7"],
      ["Purple Pants", "QmPP9edeKhcJAM2YKxVfJhLaFHmLxJLm3WGcwWBvNvGXkZ"]
    ];
  }

  function getWeaponsLength() public pure returns (uint256) {
    return getWeapons().length;
  }

  function getWeapons() public pure returns (string[2][19] memory) {
    return [
      ["", ""],
      ["Boomerang of Wood", "QmeZpiK4w2G4nQnEsm9m83h1oZXSaxX5P9tg1ai7cEzCvc"],
      ["Bow of Focus", "QmNSq5KzbDhRJNuFkUmLc3MZBe5fcVKbvQcNSfThsG4KXw"],
      ["Mythal Short Sword", "Qmbbz8kkycoEK4r3oMUyw3aqrTQbCfdTno9i9eCKfFTCmz"],
      ["Bow of Honor", "QmNMApPhGawYMQtCsVNbkD2tSsyA7wfHeNuspw8jSrFaBL"],
      ["Axe of Honor", "QmeLEVz3Jy2FhWRBrQqN8szyUhYtjFxDPGVHxnTJY1xd2h"],
      ["Wood Long Sword", "QmXnwjgest5CZVz5ZhUyNnLo1diWFhkKhBck98xY4cpvRP"],
      ["Boomerang of Flight", "QmPeNnTj25uXJz67mFrJr4ro1zxENYXAGX6kfSxAC9GBxs"],
      ["Axe of Wonder", "QmT32TRmyg1xJCA9n7oFBRcuRW5vbb5TboXh5LygyLTXbi"],
      ["Bow of Mystery", "QmbQLEKE1QbGnqNjKeBLLVwcDEoQNB98fsoEQgUbVgrPJk"],
      ["Axe of Strength", "QmRfhpxsSQHCmsxGPbSDAD7rTKAjVfqgHVBfdoVZBALWFC"],
      [
        "Elvish Staff of the Forest",
        "QmZTTFEmaGu54yj9kUwH3xL4mZrfXJXp8RtzqYMHMYww6p"
      ],
      ["Staff of the Sea", "QmUsxTdawFhmWPEbBwqRUi9SGpNBeUN8RwxUUQczxVP8TX"],
      ["Universe Staff", "Qmab3zQ2n1ZPYpTEgkivDHuryM6A5P1sTjCQoWN5N9ADWE"],
      ["Mythal Long Sword", "QmSx6MiY29hFoYV2pnehEdbmuFipwupz2y2DJZyCN54jdZ"],
      ["Wood Short Sword", "QmWFFLygzSa9UXNJAtthRAurazVXjhfZ1ZsDAAsFrKWSQm"],
      ["Boomerang of Focus", "QmXPDw8pxgnsFsGoz4bw7cWA2G1ZK1MDXArNKHr1VPv3GQ"],
      ["Iron Short Sword", "QmTqDh8schE195bh6HSsoPfYLVYZLRrXaRen92nJfZcFDC"],
      ["Iron Long Sword", "QmfYEHBEReGSDKWZuRUBMRiHGhiBo1jTFwpWnVaAG11saw"]
    ];
  }

  function getBgLength() public pure returns (uint256) {
    return getBg().length;
  }

  function getBg() public pure returns (string[26] memory) {
    return [
      "#FEDD00",
      "#74D1EA",
      "#9DE7D7",
      "#9E978E",
      "#84754E",
      "#00B08B",
      "#222223",
      "#6B4C4C",
      "#ff2424",
      "#FF808B",
      "#DF1995",
      "#C1A7E2",
      "#685BC7",
      "#DDDAE8",
      "#1B365D",
      "#A4BCC2",
      "#407EC9",
      "#009CDE",
      "#003865",
      "#40C1AC",
      "#279989",
      "#00BFB3",
      "#006F62",
      "#ADDC91",
      "#007041",
      "#58eb34"
    ];
  }

  function getRaceLength() public pure returns (uint256) {
    return getRace().length;
  }

  function getRace() public pure returns (string[2][22] memory) {
    return [
      ["Human", "QmbVrpTTEciNQPxb8TjntcmpQMDLrzgEsJxYrpGanCmH88"],
      ["Human", "QmWTzCYevtrCY9Yu9HZ1RudJ5DZ3ySMbbb6V8j1GMoFd2W"],
      ["Human", "QmYhchiEeh4iJPYSksxoUAoy9SZCCEU21UQzEyeFxWBcBj"],
      ["Undead", "QmTtNfnd3HZ7moKrzaJaYyUM5idGbKy2sgHE14fpeyU9UL"],
      ["Skeleton", "QmcMDNnc8SNjwvPBpcb6hXG3yjz9WSiQ5qzbJTZre7N2uB"],
      ["Wizard", "QmYotarEMJ98MHfZGDKhsgCcZU54EzTRPCuS88vG9PBUtd"],
      ["Ghost", "QmTuv44nHYMAix3L36HuBkPV5sQ6NPiGhxSFGSTnAHipJk"],
      ["Frogling", "QmPXTBPcjrxrjwAaH9VaLzV8uZVpHuy2VnytHT1LWsYWuX"],
      ["Pizza", "QmaJFAM6iV473UUcEQUPP7hCtP1Zh5jspvMHb9sJYiyutJ"],
      ["Slate Monkey", "QmNZezfUXKEQZkrXfobHsudcqqAECt97yYZQRUV12jkNbj"],
      ["Emerald Monkey", "Qmdy1tBPBa85TeDMYb9KVPHanU7Wor39yLEpAJwEUDfgK8"],
      ["Red Monkey", "Qmb23Pp17Xg5nBQJnfkzQ4rMWPKYnNNWqJcYDaDoJJnwSN"],
      ["Gold Slate Monkey", "QmNn3agjVqz4WFNvcm3Srzg2EuKJoJi2W2t32E1aDVhAwg"],
      ["White Monkey", "QmTH9fLyHLzbP6KXUFdJKCKYZqPUHEv7vrYeP95s8AZ57B"],
      ["Emerald Red Monkey", "QmZJQQE2QS9kMHhUe1PbCNnG1QvGH7hiW6sPETZtqpeEZK"],
      ["Yellow Monkey", "QmRdNLRMzuTmEuQZVtJAXj9ydxs3Ztb1EdCcF8eqRFQBBe"],
      ["Honey Monkey", "QmbgrRnunnkJSS9L945bvbP9gd54nRJ8D6YMi1jECvHhei"],
      ["Red Furred Monkey", "QmdHwSAhmthUbTUfSTqD7EMFWcZ13LLZbvoNTYgKjJb5Vj"],
      ["Snow Monkey", "QmYvjKEGeSZH2dMhSvgooPt5AatSZzQm2UvMBNhoKvUvER"],
      ["Brown Monkey", "QmehwhevsQdDyAoG2maHFA7Pip4x6KLVRU1KVfmV4pfDmu"],
      ["Gold Monkey", "QmTsvwBm7MTRgZBhLmV2GFtC7FzBggwcNNWDmk5iNyk2oP"],
      ["Tree Monkey", "QmYJBTHYE8WjNFV2udVre3yXTy9Y5xwScBW4bgHvaoPL5r"]
    ];
  }

  function getClothesLength() public pure returns (uint256) {
    return getClothes().length;
  }

  function getClothes() public pure returns (string[2][25] memory) {
    return [
      ["", ""],
      ["Robe of Fire", "QmUH91Yysb2SsDNKZSrkUMevUcoSU3dmcvpcozWAuEvr18"],
      ["Shirt of Mystery", "QmXRYw9yfgDYAU27KMQafT41hKQFVGJZBqwjs3nkWEUpAp"],
      ["Vest of Fire", "QmZDeqtzajKwxV9YgfzcZ8Wfap1zARUicUWjTJmJBMdQdw"],
      ["Tunic of Wonder", "QmaS95LAjXoF3EWxPowwbybBvhG7NtqAA6KeWLYpAzKUVZ"],
      ["Tunic of Mystery", "QmYJ1xzvptgSVakpUGQgaXjF4w8nnZyNCoDz9v9TJKEcpz"],
      ["Shirt of Fire", "QmQc1ThSSgbdC6z5nwLDyMyPYqrUC6JBDhfu7WWkyyx9QP"],
      ["Vest of White", "QmYXx2ihhkFWbjHGkyyfSsQf5jnHPojmo1cWBS9RNjLo8R"],
      ["Tunic of Fire", "QmcfVUUiFDNoJnZP8W8eSHPq11WRj99oeK4LLaJQtQ1fb8"],
      ["Robe of Mystery", "QmW9xSXtHfikeScmhpB56kWHdNSDPJaA2F4DRiRdS1gt96"],
      ["Robe of White", "QmRdTAV3jspvFCdWuTL1wYvz34BS1BXhUY9ctsouy11vfR"],
      ["Shirt of Emerald", "QmU3i6M3JgPUSFMzfwCjgAkcFtwtmEvwgdSvTEN9gBQ2Ld"],
      ["Vest of Mystery", "Qme5ZavY4PMvt5bSmrLJErrnDyUckaNH9FrgT5aYqdnnBf"],
      ["Robe of Emerald", "QmZynRUwPjL6Du9LsGyPA3u1fYabmKuefjRnyTgAm99S8D"],
      ["Vest of Wishing", "QmUWNR2XF8dAgPXyakxUmpbr5SWz3kytzu49dAhRBo3gLZ"],
      ["Gown of Magic", "QmQBvcfZ1tsue32nerkpRCsYzDJfNpy466zAhwZ7jWENLw"],
      ["Robe of Wonder", "Qmbidcgmae5LJqcQKoVwF1832maJ7nMdScNr79hkvMtkkd"],
      [
        "Gown of the Universe",
        "Qmehwi2m5aqrZcqUxBjeJbXRcfWjErxywu3HbwXKPZXa2p"
      ],
      ["Tunic of Light", "QmQvhTVqSFRo4zm8uye1f6tYUSUoNvksdgrDzKychyDTKR"],
      ["Snow Gown", "QmZRoMDJFGr7umyFhH6KBporsrqG7mS1d65xMtzcTHipLj"],
      ["Blue Vest", "QmXnYYxyexqF7qcYkPDhzrrzbLkwSTeHEDfwobQLvwMd75"],
      ["Gown of Flowers", "QmaG7srwBaMSUBsExqhUuAUtQbKG12qjcmT1KKoihk7n34"],
      ["White Shirt", "Qmb7iqzgFA3NcJJQutWYFgT946bcy5JwfGHevzc9TFFXt1"],
      ["Blue Shirt", "QmQosecPGEQ8qhP1AvPNrphzrga8f3jkpNvB7HPku49cej"],
      ["Tunic of Emerald", "Qmb6yH7Ss23kL75LfrJTGZXb4oNTXx8A9Uhdr18txKFbqQ"]
    ];
  }

  function getHeadLength() public pure returns (uint256) {
    return getHead().length;
  }

  function getHead() public pure returns (string[2][24] memory) {
    return [
      ["", ""],
      ["Dark Hood", "QmecUFzdxqbhzQGQzpoxqWViFXybMA4amKC9vcwddEzj3y"],
      ["Emerald Hood", "QmQR7CLWNY66kicK51cPjzpf7tcZVEVjZm8PhMtHjBJthi"],
      ["Blue Hood", "QmUEhNvJQ5PmPWvJfABNJ5mwZg9s9uANgeFh8wBfwnftk1"],
      ["White Hood", "QmSNTEq8GsBkzRq19T3Rh9jdULr46KCtKJxVEKTgUQajAo"],
      ["Red Hood", "Qmc4VPaLnV1JPUvpzsYxsKaYofaCbrhgKK3TaDcnf6tW3L"],
      ["Helmet 1", "QmcuWWeEsqWMh6ESKEi4BpbicnoqpQt5WQcLhqC9kggj2M"],
      ["Phrygian Cap", "QmRYZTTanct9LqJw6Mr4EjuTN5iGvySnbgB3GAviy9QAaX"],
      ["Reddish Hat", "QmemYuaZ6ti3f9hZB6sMnCZ9CyHnPRsBCTsSBrTGp7jgFS"],
      ["Hat of Luck", "Qmed5Ebw2HqfeDBn845Sb6UJdSFeedZvwcF2eDeDVTt5Q8"],
      ["Purple Hat", "QmTaet5S2Q8tRa6fa4REPQ3USdn7G6Ptemm4nMb3BpLhZ5"],
      ["Wizard Hat", "QmTAoe4qpfHsER7swyzbGj1zSR6GuRTsMfBaWdWQtsVUAu"],
      ["Helmet 2", "QmQd9zjzVbCEG3HTsnLSjfj4D8g2YbVAwJD9jLnf6x3SqH"],
      ["Helmet of Nebulous", "QmWEvHZyBXuezBcAFKvM55MdVWDnqQCXQXL4xDUzPCVYY6"],
      ["Helmet of Valoria", "QmZX3jJVEhJNTtQM5mTJNkfCSZxqfULsZ88bHg1ekELiGT"],
      ["Hat of White", "Qma6pcKWCwCbLdQfbLqYA8vNr8jr74uTM2dNiK5Ga6GSQL"],
      ["Helmet of Thulium", "QmWWFXsfSuSNRTN4qVdjPH9cf6bccZ3mUbJz8MXXY7Ky8n"],
      ["Helmet of Wonder", "QmNQQ9rZUscy6fLHdhqndmDm43dSe1xo45JBqkiKNN95qz"],
      ["Helmet of Valoria 2", "Qmd1Xza7bLMXNdHmpCP2Dt2Fo7YkyECnQxnsbNgPPEkipK"],
      ["Beep Bop", "QmaPxQGtBVHp7HWDmc7hjnHXCWbubNHFb3dctqetfT5S8S"],
      ["Helmet of Power", "Qmaqi98rt2oFwzjwJxbWmVgdbrjQshCPt5cCpmLUHsM9Cn"],
      ["Beep Bop 2", "QmTNiTTa7BZdAHNni9AgVdcQ86GNkDrDcmreLRRCVHnE4V"],
      ["Beep Bop 3", "QmXnP7hifqudavHmH92o9eDATz8qvpZef7CtGZDdgi5Hoz"],
      ["Helmet of the Sea", "QmXQBQtsdaM5CNC84r3LvjqsQPcBWnmsKvP2U1SdnGdHph"]
    ];
  }

  function getShoesLength() public pure returns (uint256) {
    return getShoes().length;
  }

  function getShoes() public pure returns (string[2][5] memory) {
    return [
      ["", ""],
      ["Shoes", "QmZuWKcMRRRP28eCFq7oZ19VHp5fKsHfKeLPvRh9AhQw3G"],
      ["Golden Runners", "QmSBkmnuG4N8GXMRhAMyYEqoajApFwHymt1aPcDaQXoiX8"],
      ["Blue Shoes", "QmXrspeWB4J3kSYovtuGCz6FqAs5KgxpZs13obSUoSBW3D"],
      ["Blue Boots", "QmZVtB16f6Z8MgEzkv2XCE9ayFe34tTRwouRPKbVZiNjF1"]
    ];
  }

  function getShieldsLength() public pure returns (uint256) {
    return getShields().length;
  }

  function getShadow() public pure returns (string memory) {
    return "QmcRNVeYU1CeMe2yD1HKpg5bvBQCfcW5xZp67HYSstAzSZ";
  }

  function getShields() public pure returns (string[2][11] memory) {
    return [
      ["", ""],
      [
        "Shield of the Forest 1",
        "QmVSwjgTzn7w9jYFvmzadBmFYDaTFi5H9JK8hUW5EJ6Uq3"
      ],
      ["Shield of Iron 1", "QmZWnaVywirur14yBBGfBJdQiqit6rQwB5NUAzkdJzqnPS"],
      ["Mythal Shield 2", "QmebyDHQq24xgLEjoN33aSSQUCFX3vTpf9koRo62GCB6bM"],
      ["Mythal Shield 3", "QmbVKssPYZS1V9bZmkDfpU1EqKyFSKkVLunqQasiipQCkD"],
      ["Shield of Iron 2", "QmYpmqDQZvPPQoNsiH4jDUksozTgWiK13KfWT24YorFsY7"],
      ["Mythal Shield 1", "QmT21FSftCYKcSvjK262vyw79zqQpzxuPCvPNKY23CbNzn"],
      ["Shield of Absolute", "QmPGtk89gzqK93hV8v1noqJthoB3QAccxZGVw9TZUKrKmZ"],
      [
        "Shield of the Forest 2",
        "QmcDwGHTrcdFusDAagX3632cDjAczawoWL6uChv4Y68gF2"
      ],
      ["Shield of Iron 3", "QmPvccz4cMBh3589fht4hCdwRJYyNAHMRggy4YUwKzGKv4"],
      [
        "Shield of the Forest 3",
        "QmRPvKjbSQafzLcxwU4CFBKuemNRxGBS8U3ra8rGFJRRGy"
      ]
    ];
  }
}