# HashMap、Hashtable以及ConcurrentHashMap的区别及原理

HashTable产生于JDK 1.1，HashMap产生于JDK 1.2，主要的区别有：1.线程安全2.处理速度3.使用迭代器不同4.输入参数不同5.扩充容量的大小方式不同6.计算hash以及index的方式不同。

 

1.线程安全之间的区别

    HashMap是非synchronized的，所以不能保证随着时间的推移Map中的元素次序是不变的，因为采用链表的方式来解决的，在对应的数组位置存放链表的头结点，对链表而言删除或者插入一个元素会导致新加入的节点会从头结点加入，结构上的更改指会影响到map的结构。而Hashtable是synchronized，因为它对remove，put，get进行了同步控制，保证了Hashtable的线程安全性，多个线程可以共享一个Hashtable因为任何线程要更新Hashtable时要首先获得同步锁，其它线程要等到同步锁被释放之后才能再次获得同步锁更新Hashtable。由于是线程安全的所以在单线程环境下它比HashMap要慢，如果只需要单一线程，使用HashMap性能要好过Hashtable。
    
    HashMap可以通过下面的语句进行同步：Map m = Collections.synchronizeMap(hashMap);这个方法返回一个同步的Map,封装了底层的HashMap方法，该方法只是将HashMap的操纵放在了同步代码块中来保证其线程安全性。因此SynchronizedMap也可以允许key和value为null。但也是任何一个时刻只能有一个线程可以操纵synchronizedMap，所以其效率比较低。
    
    或者使用线程安全的ConcurrentHashMap，Java 5提供了ConcurrentHashMap，它是HashTable的替代使用了锁分段技术，因为ConcurrentHashMap将Map分段了，每个段进行加锁而不是像Hashtable,SynchronizedMap是整个map加锁，这样就可以多线程访问了，ConcurrentHashMap默认运行16个线程同时访问该map。但是可以通过一个函数来设置增加或减少最大可运行访问的线程数目。

 


2.单线程情况下耗时

    （1）HashMap.put > HashTable.put，参照数据结构hasmMap的容量永远为2^*,所以HashMap在计算key所在位置时进行的位与处理会导致相同的hashcode变多，每个bucket(entry)的深度增加，所以后续put耗时较长。
    
    （2）HashMap.get < HashTable.get，在这里对于锁的处理时间时HashTable的耗时过长。Hashtable（jdk1.7版本）的注释，已经很明确的表明了如果是单线程情况下建议使用HashMap，如果是多线程的情况下建议使用ConcurrentHashMap，此处可表明HashTable自己都不建议使用自己。使用位运算(&)来代替取模运算(%)，最主要的考虑就是效率。位运算(&)效率要比代替取模运算(%)高很多，主要原因是位运算直接对内存数据进行操作，不需要转成十进制，因此处理速度非常快。Hashtable使用了取模运算而hashmap只使用了位与运算。

 


3.两者迭代器之间的区别

    HashMap的迭代器Iterator是fail-fast迭代器，而Hashtable的enumerator迭代器不是fail-fast的。fail-safe基于容器的一个克隆所以允许在遍历的过程中对容器中的数据进行修改对不影响遍历，而fail-fast则不允许，一旦发现容器中的数据被修改了，会立刻抛出异常导致遍历失败。常见的的使用fail-fast方式遍历的容器有HashMap和ArrayList等。

 


4.两者输入参数的区别

    HashMap的key-value输入支持key-value，null-null，key-null，null-value四种，null可以作为键但这样的键只有一个，但可以有一个或多个键所对应的值为null。而Hashtable只支持key-value一种。既然HashMap支持带有null的形式，那么在HashMap中不能由get()方法来判断HashMap中是否存在某个键， 而应该用containsKey()方法来判断，因为无法判断到底存不存在这个key，对于HashMap的key为null时会调用putForNullKey方法进行处理将value值放入Entry数组的第一个bucket中。

 


5.关于扩容区别

    hashtable初始size为11，扩容：扩容为原来的2倍+1（newsize = olesize*2+1），负载因子为0.75时是负载极限，如果给定了初始化大小就会直接使用。
    
    hashmap初始size为16，扩容：扩容为原来的2倍（newsize = oldsize*2），负载因子为0.75时是负载极限，如果给定了初始化大小会将大小扩充为2的幂次方大小。
    
    0.75是时间和空间成本上的一种折中：如果希望加快Key查找的时间，还可以进一步降低加载因子，加大初始大小，以降低哈希冲突的概率。较高的负载极限可以降低hash表所占用的内存空间，但会增加查询数据的时间开销，而查询是最频繁的操作。较低的负载极限会提高查询数据的性能，但会增加hash表所占用的内存开销。当容量不足超过阀值或者碰撞过多的时候就会发生扩容。
    
    HashMap的扩容针对整个Map，每次扩容时原来数组中的元素依次重新计算存放位置，并重新插入。size一定为2的n次幂在取模运算时不需要做除法，只需要位的与运算就可以，由于引入的hash冲突加剧问题，HashMap在调用了对象的hashCode方法之后，又做了一些位运算在打散数据，扩容针对整个Map，每次扩容时，原来数组中的元素依次重新计算存放位置，并重新插入，插入元素后才判断该不该扩容，有可能无效扩容（插入后如果扩容，如果没有再次插入，就会产生无效扩容）当Map中元素总数超过Entry数组的75%，触发扩容操作，为了减少链表长度，元素分配更均匀。HashMap是先插入数据再进行扩容的，但是如果是刚刚初始化容器的时候是先扩容再插入数据。

 


6.计算hash以及index的方式区别

    用hash算法根据Key来决定其元素的存储位置，因此HashMap和Hashtable的hash表包含如下属性：容量、初始化容量、尺寸、负载因子、负载极限。
    
    容量（capacity）：hash表中桶的数量。
    
    初始化容量（initial capacity）：创建hash表时桶的数量，HashMap允许在构造器中指定初始化容量。
    
    尺寸（size）：当前hash表中记录的数量。
    
    负载因子（load factor）：负载因子等于“size/capacity”。负载因子为0，表示空的hash表，0.5表示半满的散列表，依此类推。轻负载的散列表具有冲突少、适宜插入与查询的特点（但是使用Iterator迭代元素时比较慢）。
    
    负载极限：构造器允许指定一个负载极限，是一个0～1的数值，决定了hash表的最大填满程度。当hash表中的负载因子达到指定的负载极限时，hash表会自动成倍地增加容量（桶的数量），并将原有的对象重新分配，放入新的桶内，这称为rehashing。
    
    hash该方法主要是将Object转换成一个整型，基本原理是调用Object对象的hashCode()方法，该方法会返回一个整数，然后用这个数对HashMap或者HashTable的容量进行取模。在具体实现上由两个方法int hash(Object k)和int indexFor(int h, int length)来实现。hash方法的输入应该是个Object类型的Key，输出应该是个int类型的数组下标。
    
    Hashtable计算hash值，直接用key的hashCode()对数组的长度进行取模，而HashMap有内部封装的hash算法重新计算了key的hash值。计算位置索引时就是使用indexFor方法，该方法主要是将hash生成的整型转换成链表数组中的下标。Hashtable在求hash值对应的位置索引时用取模运算和位与运算，而HashMap在求位置索引时则只用位与运算。且这里一般先用hash&0x7FFFFFFF后再用length取模，&0x7FFFFFFF的目的是为了将负的hash值转化为正值，因为hash值有可能为负数，而&0x7FFFFFFF后，只有符号位改变，而后面的位都不变。
    
    hashtable计算index的方法：index = (hash & 0x7FFFFFFF) % tab.length
    
    hashmap计算index方法：index = hash & (tab.length – 1)
    
    HashMap和HashTable在计算hash时都用到了一个叫hashSeed的变量。这是因为映射到同一个hash桶内的Entry对象，是以链表的形式存在的，而链表的查询效率比较低，所以HashMap/HashTable的效率对哈希冲突非常敏感，所以可以额外开启一个可选hash（hashSeed），从而减少哈希冲突。因为这是两个类相同的一点。事实上，这个优化在JDK 1.8中已经去掉了，因为JDK 1.8中，映射到同一个哈希桶（数组位置）的Entry对象，使用了红黑树来存储，从而大大加速了其查找效率。

 


HashMap、HashTable、ConcurrentMap和其它类的关系

    HashMap是继承自AbstractMap类，而HashTable是继承自Dictionary类。不过它们都实现了同时实现了map、Cloneable（可复制）、Serializable（可序列化）这三个接口，都创建了一个继承自Map.Entry的私有的内部类Entry。HashMap遍历使用的是Iterator迭代器；HashTable遍历使用的是Enumeration列举；
    
    ConcurrentHashMap是由Segment数组结构和HashEntry数组结构组成

 


HashMap、Hashtable底层实现原理

    Hashmap和Hashtable的底层数据结构是数组+链表，称为数组链表，数组的特点是：寻址容易，插入和删除困难；而链表的特点是：寻址困难，插入和删除容易，这种组合的方法叫做链地址法，其实就是将数组和链表组合在一起，发挥了两者的优势。
    
    当系统开始初始化 HashMap 时，系统会创建一个长度为capacity的Entry数组，两个都创建了一个继承自Map.Entry的私有的内部类Entry，每一个Entry对象表示存储在哈希表中的一个键值对Entry对象唯一表示一个键值对，有四个属性：-K key 键对象、-V value 值对象、-int hash 键对象的hash值、-Entry entry 指向链表中下一个Entry对象，可为null，表示当前Entry对象在链表尾部这个数组里可以存储元素的位置被称为桶（bucket）。
    
    当将键值对传递给put()方法时调用键对象的hashCode()方法来计算hashcode，然后找到bucket位置来存储值对象，每个 bucket 都有其指定索引，系统可以根据其索引快速访问该 bucket 里存储的元素。每个bucket只指向一个 Entry，但是Entry对象本身包含一个引用变量（ 即Entry 构造器的最后一个参数）可以用于指向下一个Entry，当发生碰撞，对象将会储存在链表的下一个节点中，就会出现bucket中只有一个Entry，但这个Entry指向另一个Entry ——这就形成了一个Entry链。

   当bucket 里存储的Entry只是单个Entry 时，此时结构具有最好的性能：当程序通过key取出对应value时，系统只要先计算出该key的 hashCode() 返回值，hashCode的存在主要是用于查找的快捷性，用来在散列存储结构中确定对象的存储地址的。在根据该hashCode返回值找出该key在table数组中的索引，然后取出该索引处的Entry，最后返回该key对应的value。

    这种具有链表的结构可以有效的解决碰撞问题，当发生碰撞时对象将会储存在链表的下一个节点中。在每个链表节点中储存键值对对象。当两个不同的键对象的hashcode相同时，它们会储存在同一个bucket位置的链表中，可通过键对象的equals()方法来找到键值对。如果链表大小超过阈值，链表就会被改造为树形结构。

 


ConcurrentHashMap的实现原理

    由Segment数组结构和HashEntry数组结构组成。Segment是一种可重入锁ReentrantLock，HashEntry则用于存储键值对数据。一个ConcurrentHashMap里包含一个Segment数组，Segment的结构和HashMap类似，是一种数组和链表结构，一个Segment里包含一个HashEntry数组，每个HashEntry是一个链表结构的元素，每个Segment守护着一个HashEntry数组里的元素，一次锁住一个桶即segment，然而一个Segment里包含一个HashEntry数组，当对HashEntry数组的数据进行修改时，必须首先获得它对应的Segment锁。通过把整个Map分为N个Segment，可以提供相同的线程安全，但是效率提升N倍，默认提升16倍。读操作不加锁，由于HashEntry的value变量是 volatile的，也能保证读取到最新的值。
    
    有些方法需要跨段，比如size()和containsValue()，它们可能需要锁定整个表而而不仅仅是某个段，这需要按顺序锁定所有段，操作完毕后，又按顺序释放所有段的锁。段内元素超过该段对应Entry数组长度的75%触发扩容，不会对整个Map进行扩容），插入前检测需不需要扩容，有效避免无效扩容

 


在JDK1.7和1.8版本之间HashMap、Hashtable、ConcurrentHashMap也发生了变化

    在Java 8 之前，HashMap和其他基于map的类都是通过链地址法解决冲突，它们使用单向链表来存储相同索引值的元素。在最坏的情况下，这种方式会将HashMap的get方法的性能从O(1)降低到O(n)。为了解决在频繁冲突时hashmap性能降低的问题，Java 8中使用平衡树来替代链表存储冲突的元素。这意味着我们可以将最坏情况下的性能从O(n)提高到O(logn)。关于HashMap在Java 8中的优化。
    
    关于Java 8中的hash函数，原理和Java 7中基本类似。Java 8中这一步做了优化，只做一次16位右位移异或混合，而不是四次，但原理是不变的。
    
    ConcurrentHashMap在Java 8 里抛弃了Segment的概念，直接用Node数组+链表+红黑树的数据结构来实现，Node是ConcurrentHashMap存储结构的基本单元，继承于HashMap中的Entry，用于存储数据，并发控制使用Synchronized和CAS来操作，看起来就像是优化过且线程安全的HashMap，虽然在JDK1.8中还能看到Segment的数据结构但是已经简化了属性，认为在引入红黑树后，即使哈希冲突比较严重，寻址效率也足够高，所以并未在哈希值的计算上做过多设计，只是将Key的hashCode值与其高16位作异或并保证最高位为0。TreeNode继承自Node，但是数据结构换成了二叉树结构，它是红黑树的数据的存储结构，用于红黑树中存储数据，当链表的节点数大于8时会转换成红黑树的结构，就是通过TreeNode作为存储结构代替Node来转换成黑红树。

 




一、什么是HashMap？

    HashMap是一个用于存储Key-Value键值对的集合，每一个键值对也叫做Entry。这些个键值对分散存储在一个数组当中，这个数组就是HashMap的主干，数组每一个元素的初始值都是Null。这些就是HashMap的定义了。

 


二、你知道HashMap的工作原理吗？

    HashMap是基于hash原理，我们使用put(key, value)存储对象到HashMap中，使用get(key)从HashMap中获取对象。当我们给put()方法传递键和值时，我们先对键调用hashCode()方法，返回的hashCode用于找到bucket位置来储存Entry对象。这里关键点在于指出，HashMap是在bucket中储存键对象和值对象，作为Map.Entry。

 


三、你知道HashMap的get()方法的工作原理吗？

    首先根据对象的Hash值计算index进行数组索引的寻找(使用hashcode或者重写的hash方法)，然后找到这个数组之后，判断key是不是唯一，如果key唯一，则直接返回，如果不唯一，则使用equals进行值的判断，最后返回数据。

 


四、当两个对象的hashcode相同会发生什么？

    因为hashcode相同，所以它们的bucket位置相同会发生碰撞。因为HashMap使用链表存储对象，这个Entry(包含有键值对的Map.Entry对象)会存储在链表中。这个时候要理解根据hashcode来划分的数组，如果数组的坐标相同，则进入链表这个数据结构中了，当前传进来的参数生成一个新的节点保存在链表的尾部（JDK1.7保存在首部）。如果当链表长度到达8的时候，jdk1.8上升为红黑树进行保存。

 


五、如果两个键的hashcode相同，你如何获取值对象？

    当调用get()方法，HashMap会使用键对象的hashcode找到bucket位置，然后获取值对象，如果有两个值对象储存在同一个bucket，将会遍历链表直到找到值对象。找到bucket位置之后，会调用keys.equals()方法去找到链表中正确的节点，最终找到要找的值对象。equals()方法仅仅在获取值对象的时候才出现。使用不可变的、声明为final的对象，并且采用合适的equals()和hashCode()方法的话，将会减少碰撞的发生，提高效率。不可变性使得能够缓存不同键的hashcode，这将提高整个获取对象的速度，使用String，Interger这样的wrapper类作为键是非常好的选择。String, Interger这样的wrapper类作为HashMap的键是再适合不过了，而且String最为常用。因为String是不可变的，也是final的，而且已经重写了equals()和hashCode()方法了。其他的wrapper类也有这个特点。不可变性是必要的，因为为了要计算hashCode()，就要防止键值改变，如果键值在放入时和获取时返回不同的hashcode的话，那么就不能从HashMap中找到你想要的对象。不可变性还有其他的优点如线程安全。如果你可以仅仅通过将某个field声明成final就能保证hashCode是不变的，那么请这么做吧。因为获取对象的时候要用到equals()和hashCode()方法，那么键对象正确的重写这两个方法是非常重要的。如果两个不相等的对象返回不同的hashcode的话，那么碰撞的几率就会小些，这样就能提高HashMap的性能。

 


六、如果HashMap的大小超过了负载因子(load factor)定义的容量，怎么办？

    默认的负载因子大小为0.75，当一个map填满了75%的bucket时候，和其它集合类(如ArrayList等)一样，将会创建原来HashMap大小的两倍的bucket数组，来重新调整map的大小，并将原来的对象放入新的bucket数组中。这个过程叫作rehashing，因为它调用hash方法找到新的bucket位置。

 


七、你了解重新调整HashMap大小存在什么问题吗？

    当多线程的情况下，可能产生条件竞争。 当重新调整HashMap大小的时候，确实存在条件竞争，因为如果两个线程都发现HashMap需要重新调整大小了，它们会同时试着调整大小。在调整大小的过程中，存储在链表中的元素的次序会反过来，因为移动到新的bucket位置的时候，HashMap并不会将元素放在链表的尾部，而是放在头部，这是为了避免尾部遍历。如果条件竞争发生了，那么就死循环了。 或者可以反问为什么要在多线程的环境下使用HashMap而不直接使用concurrentHashMap。Hashtable是synchronized的，但是ConcurrentHashMap同步性能更好，因为它仅仅根据同步级别对map的一部分进行上锁。ConcurrentHashMap当然可以代替HashTable，但是HashTable提供更强的线程安全性。
————————————————
版权声明：本文为CSDN博主「ZytheMoon」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/ZytheMoon/article/details/88376749