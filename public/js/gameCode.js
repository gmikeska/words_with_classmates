
//scoreboardTemplate = _.template()
playerEntryTemplate = _.template('<b><%= name %>:</b> <%= score %><br>')
$(document).ready(function(){
	audio = {}
	$(".alert_sound").trigger('load');
	audio.alert = $(".alert_sound").trigger.bind($(".alert_sound"), 'play');
	$(".error_sound").trigger('load');
	audio.error = $(".error_sound").trigger.bind($(".error_sound"), 'play');
	$(".tile_sound").trigger('load');
	audio.tile = $(".tile_sound").trigger.bind($(".tile_sound"), 'play');
})

loadGame = function()
{
	(function() {

		var client = {}
		client.handlers = {}
		client.connected = false
		
		client.connect = function()
		{
			socket = new WebSocket("wss://words-with-classmates.herokuapp.com")
			this.socket = socket
			client = this
			this.socket.onmessage = function (event) {
		  		obj = JSON.parse(event.data)
		  		eventName = obj.eventName
		  		delete obj['eventName']
		  		client.trigger(eventName, obj)
			}
			socket.onopen = function (event) {
		 		client.connected = true
		 		client.send({eventName:"init", sessionID:sessionID})
		 		client.send({eventName:"echo", data:"CONNECTED."})

			};
		}
		client.send = function(object)
		{
			object.sessionID = sessionID
			object.userID = userID
			this.socket.send(JSON.stringify(object))
		}

		client.on = function(eventname, f)
		{	
			this.handlers[eventname] = f
		}

		client.trigger = function(fkey, arg)
		{
			arg = Object.keys(arg).map(function(x){
				return arg[x]
			})
			client.handlers[fkey].apply(client.socket, arg)
		}

		var boardMap = [
		["tw","xx","xx","dl","xx","xx","xx","tw"],
		["xx","dw","xx","xx","xx","tl","xx","xx"],
		["xx","xx","dw","xx","xx","xx","dl","xx"],
		["dl","xx","xx","dw","xx","xx","xx","dl"],
		["xx","xx","xx","xx","dw","xx","xx","xx"],
		["xx","tl","xx","xx","xx","tl","xx","xx"],
		["xx","xx","dl","xx","xx","xx","dl","xx"],
		["tw","xx","xx","dl","xx","xx","xx","dw"],
		]





		var tileMap = {
			A:{value:'1', count:'9'},
			B:{value:'3', count:'2'},
			C:{value:'3', count:'2'},
			D:{value:'2', count:'4'},
			E:{value:'1', count:'12'},
			F:{value:'4', count:'2'},
			G:{value:'2', count:'3'},
			H:{value:'4', count:'2'},
			I:{value:'1', count:'9'},
			J:{value:'8', count:'1'},
			K:{value:'5', count:'1'},
			L:{value:'1', count:'4'},
			M:{value:'3', count:'2'},
			N:{value:'1', count:'6'},
			O:{value:'1', count:'8'},
			P:{value:'3', count:'2'},
			Q:{value:'10', count:'1'},
			R:{value:'1', count:'6'},
			S:{value:'1', count:'4'},
			T:{value:'1', count:'6'},
			U:{value:'1', count:'4'},
			V:{value:'4', count:'2'},
			W:{value:'4', count:'2'},
			X:{value:'8', count:'1'},
			Y:{value:'4', count:'2'},
			Z:{value:'10', count:'1'},
			_:{value:'0', count:'2'}
		}
		var colors = {
			greenDark:"#348956",
			greenLight:"#5DA77B",
			greenLightest:"#8AC3A1",
			redDark:"#BE5F49",
			redLight:"#E99581",
			redLightest:"#FFC3B5",
			blueDark:"#335D7A",
			blueLight:"#577C95",
			blueLightest:"#829FB3",
			brownDark:"#BE8B49",
			brownLight:"#E9BC81",
			brownLightest:"#FFDFB5"
		}
	boardTheme = {
		tw:colors.redDark,
		dw:colors.redLight,
		tl:colors.blueDark,
		dl:colors.blueLight,
		xx:colors.brownDark
	}

	words = {
		dl:"Double\nLetter",
		tl:"Triple\nLetter",
		dw:"Double\nWord",
		tw:"Triple\nWord"
	}
	var canvas = oCanvas.create({
	canvas: "#game"
});
	var cellSize = 38
	var leftMargin = 20
	var topMargin = 20
	var innerMargin = 5
	var gameBoard = {
		scores:{},
		lastDropped:null,
		cells:[],
		pending:[],
		build:function(map)
		{
			bottom = map.clone().reverse()
			bottom.shift()
			map = map.concat(bottom)
			var self = this
			map.each(function(i, y){
				r = i.clone().reverse()
				r.shift()
				i = i.concat(r)

				i.each(function(j,x){
					self.makeCell(x,y,j)
				})
			})

			
			this.rack = []
			yCoord = 15
			Number.range(0,6).every(1, function(xCoord){
				var cell = canvas.display.rectangle({
				x: 4*(cellSize+innerMargin)+leftMargin+xCoord*(cellSize+innerMargin),
				y: topMargin*2+yCoord*(cellSize+innerMargin),
	  			fill: colors.brownDark,
	  			width: cellSize,
	  			height: cellSize,
	  			stroke:"outside 1px black"

			})
			
	  			cell.setLetterTile = function(l) {
					//console.log("letter set")
					this.letter = l
				}
				cell.getLetterTile = function() {
					return this.letter
				}
				cell.getX = function(){ return this.x }
				cell.getY = function(){ return this.y }
				gameBoard.rack.push(cell)
				canvas.addChild(cell);
				//canvas.renderAll()
			})
		},
		updateScore:function()
		{
			users = Object.keys(gameBoard.scores)
			lines = users.map(function(x){
				return playerEntryTemplate({name:x, score:gameBoard.scores[x]})
			})
				console.log(lines)
			$('#playerScores').html(lines)

		},
		modal:function(title, body)
		{
			$('#myModalLabel').html(title)
			$('#myModalBody').html(body)
			$('#myModal').modal()

		},
		addPlayedWord:function(entry)
		{
			$entry = $('<div>').append($('<div>').css('float','left').html('<b>'+entry.player+'</b> played:')).append('<br>')
			
			entry.words.each(function(w){
			$entry.append($('<div>').css('float','right').append('<b>'+w.text+':</b>'+w.score+' points.')).append('<br>')
				gameBoard.scores[entry.player] += w.score
			})
			gameBoard.updateScore()
			$('#gameInfo2').append($entry)
		},
		makeCell:function(xCoord, yCoord, typeCode)
		{
			var cell = canvas.display.rectangle({
	  			x:leftMargin+xCoord*(cellSize+innerMargin),
	  			y:topMargin+yCoord*(cellSize+innerMargin),
	  			fill: boardTheme[typeCode],
	  			width: cellSize,
	  			height: cellSize,
	  			stroke:"outside 1px black"
			})
			
			var txt;
			if(typeCode != "xx")
			{
				txt = canvas.display.text({

		  			x: 4,
		  			y: 4,
		  			text:words[typeCode],
		  			size: 10,
		  			align:"center",
		  			stroke:"outside 1px black"
				})
				cell.addChild(txt)
			} 


			cell.setLetterTile = function(l) {
				//console.log("letter set")
				this.letter = l
			}
			cell.getLetterTile = function() {
				return this.letter
			}

			cell.cellType = typeCode
			cell.getX = function(){ return this.x }
			cell.getY = function(){ return this.y }

			canvas.addChild(cell);

			row = this.cells[yCoord]
			if(!Array.isArray(row))
			{
				row = []
				this.cells[yCoord] = row
			}

			row.push(cell)
		},
		submit:function()
		{
			client.send({eventName:"played", tiles:gameBoard.getPendingLetters()})
		},
		reject:function()
		{
			gameBoard.pending.each(function(tile){
				gameBoard.cellAt(tile.x,tile.y).getLetterTile().remove()
			})

			gameBoard.pending = []

			gameBoard.reRack()
		},
		freezePendingLetters:function()
		{
			this.pending.each(function(x){
				x.letter.isNew = false
				x.letter.dragAndDrop(false)
			})

		},
		makeLetterTile:function(character)
		{
			console.log(character)
			if(character != null)
			{
				var tileSize = cellSize-1
				var aspect = tileSize/10
				cornerConst = 4.1176470588235485
				var back = canvas.display.rectangle({
						x: aspect,
						y: 0,
						fill: "#e08002",
						width: tileSize-aspect,
						height: tileSize-aspect
					})
				/*var tlCorner = new fabric.Triangle({
						left: aspect/cornerConst,
						top: 0,
						width:aspect*1.3,
						height:aspect*1.5,
						fill: "#e08002",
						angle:10,
						hasBorders:false,
						hasControls:false
					})
				var brCorner = new fabric.Triangle({
						left: tileSize-(aspect/cornerConst),
						top: tileSize-(aspect+2.5),
						width:aspect*1.3,
						height:aspect*1.5,
						fill: "#e08002",
						angle:60,
						hasBorders:false,
						hasControls:false
					})*/
				//console.log(brCorner)
				var front = canvas.display.rectangle({
						x: 0,
						y: aspect,
						fill: "#EDA628",
						width: tileSize-aspect,
						height: tileSize-(aspect)
				})
				var letter = canvas.display.text({
				  			x: cellSize*.25,
				  			y: cellSize*.15,
				  			text:character.letter,
				  			size: 16,
				  			align:"center",
				  			stroke:"outside 1px black"
				})
				var points = canvas.display.text({
				  			x: cellSize*.65,
				  			y: cellSize*.55,
				  			text:character.value,
				  			size: 10,
				  			align:"center",
				  			stroke:"outside 1px black"
				})

				var letterTile = canvas.display.rectangle({
					x:0,
					y:0,
					width:tileSize,
					height:tileSize,
					fill:"transparent"
				})
				letterTile.getLoc = function()
				{
					return {x:Math.round((this.x-leftMargin)/(cellSize+innerMargin)), y:Math.round((this.y-topMargin)/(cellSize+innerMargin))}
				}
				letterTile.isNew =true

				letterTile.dragAndDrop({
					start:function(){
						var self = this
						this.zIndex = "front"
						gameBoard.pending.each(function(x,i){
					    	if(x.letter == self)
					     	gameBoard.pending.removeAt(i)
						})
						this.getCell().setLetterTile(null)
						this.setCell(null)
					},
					end:function(){
						x = this.abs_x
						y = this.abs_y
						x = Math.round((x-leftMargin)/(cellSize+innerMargin))
						y = Math.round((y-topMargin)/(cellSize+innerMargin))
						if(x>14 || y>14)
						{
							console.log('dropped at('+x+','+y+')')
							gameBoard.rackTile(x-4, this)
						}
						else
						{
							/*console.log('placing on board')*/
							gameBoard.placeTile(x,y, this)
						}

				}})
				letterTile.addChild(back)
				letterTile.addChild(front)
				letterTile.addChild(letter)
				letterTile.addChild(points)

				letterTile.value = parseInt(character.value)
				letterTile.id = character.id
				letterTile.gameBoard = this
				letterTile.letterElement = letter
				letterTile.cell = null
				letterTile.setCell = function(c){
					this.cell = c
				}
				letterTile.getCell = function(){
					return this.cell
				}
				letterTile.toLeft = function(){
					return gameBoard.cellAt(this.getLoc().x-1, this.getLoc().y).getLetterTile()
				}
				letterTile.toRight = function(){
					return gameBoard.cellAt(this.getLoc().x+1, this.getLoc().y).getLetterTile()
				}
				letterTile.toBelow = function(){
					return gameBoard.cellAt(this.getLoc().x, this.getLoc().y+1).getLetterTile()
				}
				letterTile.toAbove = function(){
					return gameBoard.cellAt(this.getLoc().x, this.getLoc().y-1).getLetterTile()
				}
				letterTile.getLetter = function(){
					return this.letterElement.text
				}
				letterTile.setLetter = function(s){
					this.letterElement.text = s
					this.letterElement.redraw
				}
				letterTile.getScore = function(){
					switch(this.getCell().cellType)
					{
						case "dl":
							return this.value*2;
							break;
						case "tl":
							return this.value*2;
							break;
						default:
							return this.value;
					}
				}
				letterTile.words = function(restrict)
				{
					console.log(this.getLetter())
					var results = []
					var tileLeft = this.toLeft()
					var tileAbove = this.toAbove()
					var leftMost
					var topMost

					while(tileLeft != undefined && restrict != "vertical")
					{
						leftMost = tileLeft
						tileLeft = tileLeft.toLeft()
					}
					if(leftMost && restrict != "vertical")
					{
						var w = [leftMost]
						r = leftMost.toRight()
						while(r != undefined)
						{
							leftMost = r
							w.push(r)
							if(r.isNew && r != gameBoard.lastDropped)
							{
								results.push(r.words("vertical"))
							}

							r = leftMost.toRight()

						}
						if(w != undefined)
							results.push(w)
					}

					while(tileAbove != undefined && restrict != "horizontal")
					{
						topMost = tileAbove
						tileAbove = tileAbove.toAbove()
					}
					if(topMost && restrict != "horizontal")
					{
						var w = [topMost]
						r = topMost.toBelow()
						while(r != undefined)
						{
							topMost = r
							w.push(r)
							if(r.isNew && r != gameBoard.lastDropped)
							{
								results.push(r.words("horizontal"))
							}

							r = topMost.toBelow()

						}
						if(w != undefined)
							results.push(w)	
					}

					return results
				}
				canvas.addChild(letterTile)
				return letterTile
			}
		},
		cellAt:function(x,y)
		{
			if(y<15)
				return this.cells[y][x]
		},
		reRack:function()
		{

			Number.range(0,6).every(function(x){

				if(gameBoard.rack[x].letter != null)
					gameBoard.rack[x].letter.remove()
				if(playerRack[x] && playerRack[x].letter)
			    gameBoard.rackTile(x, gameBoard.makeLetterTile(playerRack[x]))
			    
			})
		},
		tileAt:function(x,y)
		{
			return this.cellAt(x,y).getLetter()
		},
		placeTile:function(x,y,tile)
		{
			audio.tile()
			this.lastDropped = tile
			if(tile.getLetter() == '_')
				tile.setLetter(prompt('What letter would you like to set for this.').toUpperCase())
			var cell = gameBoard.cells[y][x]
			//gameBoard[y][x].add(e.target)
			tile.moveTo(cell.getX(),cell.getY())
			tile.redraw()
			tile.setCell(this.cellAt(x,y))
			this.cellAt(x,y).setLetterTile(tile)
			if(client.connected)
			{
				// client.send({
				// 	eventName:"boardState.update",
				// 	sessionID: sessionID,
				// 	x:x,
				// 	y:y,
				// 	letter:tile.getLetter()
				// })
				gameBoard.pending.push({x:x,
									y:y,
									letter:tile})
			}

		},
		rackTile:function(x, tile)
		{
			this.lastDropped = tile

			var cell = gameBoard.rack[x]
			tile.moveTo(cell.getX(),cell.getY())
			tile.redraw()
			tile.setCell(this.rack[x])
			this.rack[x].setLetterTile(tile)
		}
	}
	gameBoard.getPendingLetters = function(){
   			return gameBoard.pending.map(function(n){
				return {x:n.x, y:n.y, letter:n.letter.getLetter(), value:n.letter.value, id:n.letter.id}
			})
		}
	Window.gameBoard = gameBoard
	Window.client = client
	widthTotal = 2*leftMargin+(cellSize+innerMargin)*15
	heightTotal = 5*topMargin+(cellSize+innerMargin)*15

	var rect = canvas.display.rectangle({
		x: 0,
		y: 0,
		fill: colors.blueLightest,
		width: widthTotal,
		height: heightTotal
	});


	canvas.addChild(rect);



	gameBoard.build(boardMap)
	// canvas.on("mouse:up", function(e){
	// 	if(e.target && e.target.selectable)
	// 	{
	// 		console.log(e.target)
	// 		x = e.target.getCenterPoint().x
	// 		y = e.target.getCenterPoint().y
	// 		x = Math.round((x-leftMargin)/cellSize)-1
	// 		y = Math.round((y-topMargin)/cellSize)-1

	// 		if(x>14 || y>14)
	// 		{
	// 			console.log('dropped at('+x+','+y+')')
	// 			gameBoard.rackTile(x-4, e.target)
	// 		}
	// 		else
	// 		{
	// 			console.log('placing on board')
	// 			gameBoard.placeTile(x,y, e.target)
	// 		}
	// 	}
		
		
	// })

	Window.canvas = canvas
	Window.cellSize = cellSize


	})();
}

function loadEvents()
{
	client.on('console.log', function(x){
		console.log(x)
	})

	client.on('error', function(x){
		console.error(x)
	})

	client.on('currentUser.update', function(x){
		currentPlayer = x
		$('h2','#gameInfo').text("It's "+currentPlayer+"'s turn.")
	})

	client.on('rack.update', function(x){
		x = JSON.parse(x)
		playerRack = x
		gameBoard.reRack()
	})

	client.on('words.played', function(x){
		console.log("Word played")
		gameBoard.freezePendingLetters()
		gameBoard.addPlayedWord(x)

		gameBoard.updateScore()
		$('#gameInfo2').append($entry)
		console.log(x)
	})

	client.on("boardState.update", function(x){
		console.log('boardState.update')
		gameBoard.freezePendingLetters()
		x = JSON.parse(x)
		x.each(function(i){
			console.log(i)
			if(i.letter)
			{
				//console.log(i.letter)
				tile = gameBoard.makeLetterTile(i)
				gameBoard.placeTile(i.x,i.y, tile)
				tile.isNew = false
				tile.dragAndDrop(false)
			}
		})

	})

	client.on("words.reject", function(x){
		gameBoard.reject()
		console.log(x)

		if(x.length == 1)
		{	
			infoString = "Sorry, "+x[0] +" is not a valid word."
				
		}
		else
		{
			last = x.pop()
			infoString = "Sorry, "+x.join(', ') +  " and "+last+" are not valid words."	
		}
		gameBoard.modal("Invalid", infoString)
	})
	
}
