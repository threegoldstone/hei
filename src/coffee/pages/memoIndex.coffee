Modifier = require 'famous/core/Modifier'
Transform = require 'famous/core/Transform'
Surface = require 'famous/core/Surface'
ContainerSurface = require 'famous/surfaces/ContainerSurface'
Scrollview = require 'famous/views/Scrollview'
FlexibleLayout = require 'famous/views/FlexibleLayout'

Page = require '../lib/page.coffee'
FloatButton = require '../lib/widgets/FloatButton.coffee'

Memo = require '../models/Memo.coffee'

window.Memo = Memo # Warning: Only for testing, remove it when finished

util = require '../lib/util.coffee'

# Size Constants
SCREEN_SIZE = [720, 1280] # iphone5

WIDTH_RATIO = window.innerWidth / SCREEN_SIZE[0]
HEIGHT_RATIO = window.innerHeight / SCREEN_SIZE[1]

SIZE_CONST =
  ITEM:
    NetHeight: 145  * HEIGHT_RATIO
    DateHeight: 27 * HEIGHT_RATIO
    TimeHeight: 40 * HEIGHT_RATIO
    DateTopPad: 36 * HEIGHT_RATIO
    DateSectionWidth: 146 * WIDTH_RATIO
    NameLeftPad: 40 * WIDTH_RATIO
    BorderWidth: 2
    ButtonSectionWidth: 90 * WIDTH_RATIO
    ButtonRadius: 27 * WIDTH_RATIO

  FONT:
    Date: 27 * HEIGHT_RATIO
    Time: 40 * HEIGHT_RATIO
    Name: 40 * HEIGHT_RATIO

  ADD_BUTTON:
    RightPad: 60 * HEIGHT_RATIO
    BottomPad: 60 * HEIGHT_RATIO
    Size: 155 * HEIGHT_RATIO
    FontSize: 100 * HEIGHT_RATIO

CHINESE_WEEKDAY_NAMES = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

buildDateHTML = (datetime) ->
  "<div class='datetime'>" +
    "<div class='date' style='padding-top:#{SIZE_CONST.ITEM.DateTopPad}px;height:#{SIZE_CONST.ITEM.DateHeight}px;font-size:#{SIZE_CONST.FONT.Date}px;'>" +
      "<span class='month-day'>#{datetime.getMonth()+1}.#{datetime.getDate()}</span>" + "#{CHINESE_WEEKDAY_NAMES[datetime.getDay()]}" +
    "</div>" +
    "<div class='time' style='height:#{SIZE_CONST.FONT.Time}px;font-size:#{SIZE_CONST.FONT.Time}px;'>" + util.formatTime(datetime) + "</div>" +
  "</div>"

buildCircleButton = (radius, isRepeated) ->
  new Surface(
    size: [radius * 2, radius * 2]
    properties:
      borderRadius: radius + 'px'
      border: '1px solid #9da9ab'
  )

buildItem = (memo, scroll) ->
  name = memo.get('name')
  datetime = memo.get('date')
  isRepeated = memo.isRepeated()
  itemWrapper = new ContainerSurface(
    size: [undefined, SIZE_CONST.ITEM.NetHeight + SIZE_CONST.ITEM.BorderWidth]
    classes: if isRepeated then ['item', 'repeated'] else ['item']
    properties:
      overflow: 'hidden'
  )
  itemLayout = new FlexibleLayout(
    direction: 0
    ratios: [true, 1, true]
  )

  dateTimeSection = new Surface(
    content: if (datetime && datetime.getDate) then buildDateHTML datetime else ''
    size: [SIZE_CONST.ITEM.DateSectionWidth, undefined]
  )
  nameSection = new Surface(
    content: name
    size: [undefined, undefined]
    properties:
      fontSize: SIZE_CONST.FONT.Name + 'px'
      lineHeight: SIZE_CONST.ITEM.NetHeight + 'px'
      paddingLeft: SIZE_CONST.ITEM.NameLeftPad + 'px'
  )

  nameSection.on 'click', ->
    page.jumpTo 'editMemo', memo 

  buttonSection = new ContainerSurface(
    size: [SIZE_CONST.ITEM.ButtonSectionWidth, undefined]
  )
  button = buildCircleButton SIZE_CONST.ITEM.ButtonRadius, isRepeated
  buttonSection.add(new Modifier(
    origin: [.5, .5]
    align: [.5, .5]
  )).add button

  itemLayout.sequenceFrom [dateTimeSection, nameSection, buttonSection]
  itemWrapper.add itemLayout
  itemWrapper.pipe scroll
  itemWrapper

# history memos
memos = JSON.parse(window.localStorage.getItem(Memo.STORAGE_NAME) or '[]').map (data) ->
  data.date = new Date(data.date)
  new Memo data
  #memo = new Memo data
  #memo

page = new Page(
  name: 'memoIndex'
)

container = new ContainerSurface(
  size: [window.innerWidth, window.innerHeight]
  properties:
    overflow: 'hidden'
)

memoList = new Scrollview()

memoRenderItems = memos.map (memo, index) ->
  buildItem memo, memoList

addButtonMod = new Modifier(
  origin: [1,1]
  align: [1,1]
  transform: Transform.translate(0 - SIZE_CONST.ADD_BUTTON.RightPad, 0 - SIZE_CONST.ADD_BUTTON.BottomPad, 0)
)
ADD_BUTTON_SIZE = SIZE_CONST.ADD_BUTTON.Size

addButton = new FloatButton(
  type: 'image'
  imgsrc: './img/ic_add_24px.svg'
  size: [ADD_BUTTON_SIZE, ADD_BUTTON_SIZE]
  classes: ['add-button', 'md-button', 'md-fab']
  properties:
    textAlign: 'center'
    color: 'white'
    fontSize: "#{SIZE_CONST.ADD_BUTTON.FontSize}px"
    borderRadius: "50%"
)

addButton.on 'click', ->
  page.jumpTo 'editMemo'

memoList.sequenceFrom memoRenderItems
container.add memoList
container.add addButtonMod
         .add addButton
page.add container

page.onEvent 'beforeEnter', (memo) ->
  #console.log memos
  #console.log memo
  if memo and memo.isRepeated # duck typing
    idx = memos.map((m) ->
      m.get('id')
    ).indexOf memo.get('id')
    if idx isnt -1 # memo exists
      memos[idx] = memo
      memoRenderItems[idx] = buildItem memo, memoList
      memoList.sequenceFrom memoRenderItems
    else
      memos.push(memo)
      memoRenderItems.push(buildItem memo, memoList)


page.onEvent 'afterEnter', (data) ->
  console.log 'after enter'

module.exports = page
